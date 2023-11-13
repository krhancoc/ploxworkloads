#!/usr/bin/env bash
SYS_read=3
SYS_write=4
SYS_open=5
SYS_recvmsg=27
SYS_sendmsg=28
SYS_recvfrom=29
SYS_accept=30
SYS_fcntl=92
SYS_select=93
SYS_socket=97
SYS_connect=98
SYS_bind=104
SYS_setsockopt=105
SYS_listen=106
SYS_getsockopt=118
SYS_sendto=133
SYS_poll=209
SYS_mmap=477
SYS_truncate=479
SYS_ftruncate=480
SYS_accept4=541
SYS_fstatat=552
SYS_kevent=560
SYS_all=9999

#COVERAGE="$SYS_all"
COVERAGE="$SYS_read $SYS_write $SYS_open $SYS_recvmsg $SYS_sendmsg $SYS_recvfrom $SYS_accept \
  $SYS_select $SYS_socket $SYS_connect $SYS_sendto $SYS_poll $SYS_mmap $SYS_truncate $SYS_ftruncate \
  $SYS_accept4 $SYS_fstatat $SYS_bind $SYS_setsockopt $SYS_getsockopt $SYS_fcntl $SYS_listen $SYS_kevent $SYS_all"

run_cmd_startup ()
{
	touch /tmp/kcov.log
	chmod a+rwx /tmp/kcov.log

	make -C $ROOT/libcoverage clean
	make -C $ROOT/libcoverage CFLAGS="-DSYSCALL_TRACE_NUMBER=$NUM $1"
}

run_cmd_end() {
	sudo mkdir -p "$OUTPUT/$NUM"
	sudo chmod a+rwx "$OUTPUT/$NUM"
	if [ ! -e "$OUTPUT/$NUM/$1" ]; then
		touch "$OUTPUT/$NUM/$1"
	fi
	sudo cat "/tmp/kcov.log" "$OUTPUT/$NUM/$1" > "/tmp/kcovtmp"
	sudo sort -u "/tmp/kcovtmp" > "$OUTPUT/$NUM/$1"
	sudo chmod a+rw "$OUTPUT/$NUM/$1"
	sudo rm "/tmp/kcov.log"
	sudo rm -rf "logs/*"
}

run_analysis() {
	sudo chmod -R a+rw "$OUTPUT"
	sudo chmod 700 /dev/kcov

	for NUM in $COVERAGE
	do
		echo "Analysis of $NUM"
		$ROOT/bcpi/scripts/analyze-kcov.sh -a KcovAnalysis $ROOT/bcpi/kernel.full $OUTPUT/$NUM/kcov-exclusive.log  > $OUTPUT/$NUM/analysis-exclusive.txt
		$ROOT/bcpi/scripts/analyze-kcov.sh -a KcovAnalysis $ROOT/bcpi/kernel.full $OUTPUT/$NUM/kcov-inclusive.log  > $OUTPUT/$NUM/analysis-inclusive.txt
	done
}
