#!/usr/bin/env bash

ROOT=$(realpath "$(dirname "$0")/..")
source $ROOT/scripts/syscalls.sh

BENCH="redis-benchmark"
LIBCOVERAGE="$ROOT/libcoverage/libcoverage.so"
REDIS="redis-server"

OUTPUT="$ROOT/out/redis/"


sudo mkdir -p $OUTPUT
sudo chmod a+rwx $OUTPUT

sudo rm /tmp/kcov.log > /dev/null 2> /dev/null
sudo rm "$ROOT/bcpi/ghidra/projects/kernel.full.lock*"

kill -9 $(pgrep $REDIS) > /dev/null 2> /dev/null

for NUM in $COVERAGE
do
	for ITER in {1..5}
	do
		echo "Coverage of $NUM-$ITER"
		echo "SYSCALL_TRACE_NUMBER=$NUM LD_PRELOAD=$LIBCOVERAGE $REDIS $ROOT/configs/redis.conf"
		sudo SYSCALL_TRACE_NUMBER=$NUM LD_PRELOAD=$LIBCOVERAGE $REDIS $ROOT/configs/redis.conf
		sleep 1
		$BENCH -h 127.0.0.1 -p 19999 -q -c 10 > /dev/null &
		sleep 5
		sudo kill -9 $(pgrep redis-benchmark) > /dev/null 2> /dev/null
		sudo kill -9 $(pgrep $REDIS) > /dev/null 2> /dev/null
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

