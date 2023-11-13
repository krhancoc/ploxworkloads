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
		echo "LD_PRELOAD=$LIBCOVERAGE $MEMCACHED -l 127.0.0.1 -p 19999"

		run_cmd_startup ""

		sudo LD_PRELOAD=$LIBCOVERAGE $MEMCACHED -u root -l 127.0.0.1 -p 19999 &
		sleep 1
		$MEMSLAP -s 127.0.0.1:19999 > /dev/null
		sudo kill -9 $(pgrep memcached) > /dev/null 2> /dev/null

		run_cmd_end "kcov-exclusive.log"
	done

	for ITER in {1..5}
	do
		echo "Coverage of $NUM-$ITER"
		echo "LD_PRELOAD=$LIBCOVERAGE $MEMCACHED -l 127.0.0.1 -p 19999"

		run_cmd_startup "-DINCLUSIVE=1"

		sudo LD_PRELOAD=$LIBCOVERAGE $MEMCACHED -u root -l 127.0.0.1 -p 19999 &
		sleep 1
		$MEMSLAP -s 127.0.0.1:19999 > /dev/null
		sudo kill -9 $(pgrep memcached) > /dev/null 2> /dev/null

		run_cmd_end "kcov-inclusive.log"
	done

done


run_analysis

