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
		echo "LD_PRELOAD=$LIBCOVERAGE $REDIS $ROOT/configs/redis.conf"

		run_cmd_startup ""

		sudo LD_PRELOAD=$LIBCOVERAGE $REDIS $ROOT/configs/redis.conf
		sleep 1
		$BENCH -h 127.0.0.1 -p 19999 -q -c 10 > /dev/null &
		sleep 5
		sudo kill -9 $(pgrep redis-benchmark) > /dev/null 2> /dev/null
		sudo kill -9 $(pgrep $REDIS) > /dev/null 2> /dev/null

		run_cmd_end "kcov-exclusive.log"
	done

	for ITER in {1..5}
	do
		echo "Coverage of $NUM-$ITER"
		echo "LD_PRELOAD=$LIBCOVERAGE $REDIS $ROOT/configs/redis.conf"

		run_cmd_startup "-DINCLUSIVE=1"

		sudo LD_PRELOAD=$LIBCOVERAGE $REDIS $ROOT/configs/redis.conf
		sleep 1
		$BENCH -h 127.0.0.1 -p 19999 -q -c 10 > /dev/null &
		sleep 5
		sudo kill -9 $(pgrep redis-benchmark) > /dev/null 2> /dev/null
		sudo kill -9 $(pgrep $REDIS) > /dev/null 2> /dev/null

		run_cmd_end "kcov-inclusive.log"
	done

done


run_analysis

