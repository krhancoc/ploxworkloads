#/usr/bin/env bash

run_lighttpd_with_plox() {
	ROOT=$(realpath "$(dirname "$0")/..")

	DIRNAME="lighttpd-1.4.72"
	LIGHTTPD="$ROOT/$DIRNAME/src/lighttpd"
	CONFIG="$ROOT/configs/lighttpd.conf"

	sudo $PLOXD/build/src/ploxd/plox $LIGHTTPD -f $CONFIG -D
}


run_lighttpd() {
	ROOT=$(realpath "$(dirname "$0")/..")

	DIRNAME="lighttpd-1.4.72"
	LIGHTTPD="$ROOT/$DIRNAME/src/lighttpd"
	CONFIG="$ROOT/configs/lighttpd.conf"

	sudo $LIGHTTPD -f $CONFIG -D
}

run_redis()
{
	ROOT=$(realpath "$(dirname "$0")/..")
	REDIS="redis-server"
	sudo $REDIS $ROOT/configs/redis.conf
}

run_redis_with_plox()
{
	ROOT=$(realpath "$(dirname "$0")/..")
	REDIS="redis-server"
	sudo $PLOXD/build/src/ploxd/plox $REDIS $ROOT/configs/redis.conf
}


run_redis_benchmark()
{
	ROOT=$(realpath "$(dirname "$0")/..")
	BENCH="redis-benchmark"
	$BENCH -h 127.0.0.1 -p 19999 -q -c 10 -n 25000 --csv
}


run_wrk() {
	ROOT=$(realpath "$(dirname "$0")/..")

	DIRBENCH="wrk"
	WRK="$ROOT/$DIRBENCH/wrk"

	$WRK -t 8 -c 16 -d 30s --latency "http://127.0.0.1:19999"
}
