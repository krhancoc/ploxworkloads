#!/usr/bin/env bash

ROOT=$(realpath "$(dirname "$0")/..")
source $ROOT/scripts/syscalls.sh

SQLITE="sqlite"
CONFIG="$ROOT/configs/nginx.conf"
DBBENCH="$ROOT/dbbench-0.6.10/dbbench"
LIBCOVERAGE="$ROOT/libcoverage/libcoverage.so"

OUTPUT="$ROOT/out/sqlite/"

sudo mkdir -p $OUTPUT
sudo chmod a+rwx $OUTPUT

sudo rm /tmp/kcov.log > /dev/null 2> /dev/null
sudo rm "$ROOT/bcpi/ghidra/projects/kernel.full.lock*"

kill -9 $(pgrep sqlite) > /dev/null 2> /dev/null

for NUM in $COVERAGE
do
	for ITER in {1..5}
	do
		echo "Coverage of $NUM-$ITER"
		echo "sudo LD_PRELOAD=$LIBCOVERAGE $DBBENCH sqlite --iter 50 --threads 8"
		make -C $ROOT/libcoverage clean
		make -C $ROOT/libcoverage CFLAGS=-DSYSCALL_TRACE_NUMBER=$NUM
		sudo LD_PRELOAD=$LIBCOVERAGE $DBBENCH sqlite --iter 50 --threads 8 > /dev/null
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

