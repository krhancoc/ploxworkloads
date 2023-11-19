#!/usr/bin/env bash

ROOT=$(realpath "$(dirname "$0")/..")
source "$ROOT/scripts/syscalls.sh"

DIRNAME="lighttpd-1.4.72"
LIGHTTPD="$ROOT/$DIRNAME/src/lighttpd"
CONFIG="$ROOT/configs/lighttpd.conf"
DIRBENCH="wrk"
WRK="$ROOT/$DIRBENCH/wrk"
LIBCOVERAGE="$ROOT/libcoverage/libcoverage.so"
YELLCOVERAGE="/home/ryan/ploxd/build/src/overlay/liboverlay.so"

OUTPUT="$ROOT/out/lighttpd/"


sudo mkdir -p $OUTPUT
sudo chmod a+rwx $OUTPUT

sudo rm /tmp/kcov.log > /dev/null 2> /dev/null
sudo rm "$ROOT/bcpi/ghidra/projects/kernel.full.lock*"

kill -9 $(pgrep lighttpd) > /dev/null 2> /dev/null

for NUM in $COVERAGE
do
	for ITER in {1..10}
	do
		echo "Coverage of $NUM-$ITER"
		echo "LD_PRELOAD=$LIBCOVERAGE $LIGHTTPD -f $CONFIG"

		run_cmd_startup ""

		sudo LD_PRELOAD=$LIBCOVERAGE $LIGHTTPD -f $CONFIG > /dev/null
		$WRK -t 2 -c 10 -d 120s --latency "http://127.0.0.1:19999" > /dev/null
		sudo kill -9 $(pgrep lighttpd)

		run_cmd_end "kcov-exclusive.log"

		sudo rm -rf $ROOT/logs/*
	done

	for ITER in {1..10}
	do
		echo "Coverage of $NUM-$ITER"
		echo "LD_PRELOAD=$LIBCOVERAGE $LIGHTTPD -f $CONFIG"

		run_cmd_startup "-DINCLUSIVE=1"

		sudo LD_PRELOAD=$LIBCOVERAGE $LIGHTTPD -f $CONFIG > /dev/null
		$WRK -t 2 -c 10 -d 120s --latency "http://127.0.0.1:19999" > /dev/null
		sudo kill -9 $(pgrep lighttpd)

		run_cmd_end "kcov-inclusive.log"

		sudo rm -rf $ROOT/logs/*
	done

done

