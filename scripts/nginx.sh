#!/usr/bin/env bash

ROOT=$(realpath "$(dirname "$0")/..")
source $ROOT/scripts/syscalls.sh

NGINX="nginx"
CONFIG="$ROOT/configs/nginx.conf"
DIRBENCH="wrk"
WRK="$ROOT/$DIRBENCH/wrk"
LIBCOVERAGE="$ROOT/libcoverage/libcoverage.so"

OUTPUT="$ROOT/out/nginx/"


sudo mkdir -p $OUTPUT
sudo chmod a+rwx $OUTPUT
sudo chmod 777 /dev/kcov

sudo rm /tmp/kcov.log > /dev/null 2> /dev/null
sudo rm "$ROOT/bcpi/ghidra/projects/kernel.full.lock*"

kill -9 $(pgrep nginx) > /dev/null 2> /dev/null

for NUM in $COVERAGE
do
	for ITER in {1..5}
	do
		echo "Coverage of $NUM-$ITER"
		echo "sudo LD_PRELOAD=$LIBCOVERAGE $NGINX -c $CONFIG -e $ROOT/logs/error.log"
		make -C $ROOT/libcoverage clean
		make -C $ROOT/libcoverage CFLAGS=-DSYSCALL_TRACE_NUMBER=$NUM
		sudo LD_PRELOAD=$LIBCOVERAGE $NGINX -c "$CONFIG" -e "$ROOT/logs/error.log" &
		sleep 2
		$WRK -t 2 -c 10 -d 5s --latency "http://127.0.0.1:19999" > /dev/null
		sudo kill -3 $(pgrep nginx)
		sleep 1
		sudo mkdir -p "$OUTPUT/$NUM"
		sudo chmod a+rwx "$OUTPUT/$NUM"
		if [ ! -e "$OUTPUT/$NUM/kcov.log" ]; then
			touch "$OUTPUT/$NUM/kcov.log"
		fi
		sudo cat "/tmp/kcov.log" "$OUTPUT/$NUM/kcov.log" > "/tmp/kcovtmp"
		sudo sort -u "/tmp/kcovtmp" > "$OUTPUT/$NUM/kcov.log"
		sudo chmod a+rw "$OUTPUT/$NUM/kcov.log"
		sudo rm "/tmp/kcov.log"
		sudo rm -rf "logs/*"
	done
done

sudo chmod -R a+rw "$OUTPUT"
sudo chmod 700 /dev/kcov

for NUM in $COVERAGE
do
	$ROOT/bcpi/scripts/analyze-kcov.sh -a KcovAnalysis $ROOT/bcpi/kernel.full $OUTPUT/$NUM/kcov.log  > $OUTPUT/$NUM/analysis.txt
done

