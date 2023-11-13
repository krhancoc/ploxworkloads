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
		run_cmd_startup ""

		sudo LD_PRELOAD=$LIBCOVERAGE $NGINX -c "$CONFIG" -e "$ROOT/logs/error.log" &
		sleep 2
		$WRK -t 2 -c 10 -d 5s --latency "http://127.0.0.1:19999" > /dev/null
		sudo kill -3 $(pgrep nginx)
		sleep 1

		run_cmd_end "kcov-exclusive.log"
	done

	for ITER in {1..5}
	do
		run_cmd_startup "-DINCLUSIVE=1"

		sudo LD_PRELOAD=$LIBCOVERAGE $NGINX -c "$CONFIG" -e "$ROOT/logs/error.log" &
		sleep 2
		$WRK -t 2 -c 10 -d 5s --latency "http://127.0.0.1:19999" > /dev/null
		sudo kill -3 $(pgrep nginx)
		sleep 1

		run_cmd_end "kcov-inclusive.log"
	done

done

run_analysis
