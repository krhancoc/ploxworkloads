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
	for ITER in {1..10}
	do
		echo "Coverage of $NUM-$ITER"
		echo "sudo LD_PRELOAD=$LIBCOVERAGE $DBBENCH sqlite --iter 3 --threads 4"

		run_cmd_startup ""

		sudo LD_PRELOAD=$LIBCOVERAGE $DBBENCH sqlite --iter 3 --threads 4 > /dev/null

		run_cmd_end "kcov-exclusive.log"
	done

	for ITER in {1..10}
	do
		echo "Coverage of $NUM-$ITER"
		echo "sudo LD_PRELOAD=$LIBCOVERAGE $DBBENCH sqlite --iter 3 --threads 4"

		run_cmd_startup "-DINCLUSIVE=1"

		sudo LD_PRELOAD=$LIBCOVERAGE $DBBENCH sqlite --iter 3 --threads 4 > /dev/null

		run_cmd_end "kcov-inclusive.log"
	done

done
