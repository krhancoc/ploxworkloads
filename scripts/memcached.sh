#!/usr/bin/env bash

ROOT=$(realpath "$(dirname "$0")/..")
source $ROOT/scripts/syscalls.sh

DIRNAME="libmemcached-1.0.18"
MEMSLAP="$ROOT/$DIRNAME/clients/memslap"
LIBCOVERAGE="$ROOT/libcoverage/libcoverage.so"
MEMCACHED="memcached"

OUTPUT="$ROOT/out/memcached/"


sudo mkdir -p $OUTPUT
sudo chmod a+rwx $OUTPUT

sudo rm /tmp/kcov.log > /dev/null 2> /dev/null
sudo rm "$ROOT/bcpi/ghidra/projects/kernel.full.lock*"

kill -9 $(pgrep memcached) > /dev/null 2> /dev/null

for NUM in $COVERAGE
do
	for ITER in {1..5}
	do
		echo "Coverage of $NUM-$ITER"
		echo "SYSCALL_TRACE_NUMBER=$NUM LD_PRELOAD=$LIBCOVERAGE $MEMCACHED -l 127.0.0.1 -p 19999"
		sudo SYSCALL_TRACE_NUMBER=$NUM LD_PRELOAD=$LIBCOVERAGE $MEMCACHED -u root -l 127.0.0.1 -p 19999 &
		sleep 1
		$MEMSLAP -s 127.0.0.1:19999 > /dev/null
		sudo kill -9 $(pgrep memcached) > /dev/null 2> /dev/null
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

for NUM in $COVERAGE
do
	$ROOT/bcpi/scripts/analyze-kcov.sh -a KcovAnalysis $ROOT/bcpi/kernel.full $OUTPUT/$NUM/kcov.log  > $OUTPUT/$NUM/analysis.txt
done

