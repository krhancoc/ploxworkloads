#/usr/bin/env bash
build_kplox() {
	make -C $PLOXD/kplox -j 8 clean
	CFLAGS="\"$1\"" make -C $PLOXD/kplox -j 8
}

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

run_sqlite() {
	ROOT=$(realpath "$(dirname "$0")/..")
	source $ROOT/scripts/syscalls.sh

	DBBENCH="$ROOT/dbbench-0.6.10/dbbench"

	$DBBENCH sqlite --iter 2000 --threads 4
}

run_memcached()
{
	ROOT=$(realpath "$(dirname "$0")/..")
	MEMCACHED="memcached"
	sudo $MEMCACHED -u root -l 127.0.0.1 -p 19999 
}

run_memaslap()
{
	ROOT=$(realpath "$(dirname "$0")/..")
	DIRNAME="libmemcached-1.0.18"
	MEMASLAP="memaslap"

	$MEMASLAP -s 127.0.0.1:19999 -t 60s
}

run_memcached_with_plox()
{
	ROOT=$(realpath "$(dirname "$0")/..")
	MEMCACHED=$(which memcached)

	sudo $PLOXD/build/src/ploxd/plox $MEMCACHED -u root -l 127.0.0.1 -p 19999 
}


run_sqlite_with_plox() {
	ROOT=$(realpath "$(dirname "$0")/..")
	source $ROOT/scripts/syscalls.sh

	DBBENCH="$ROOT/dbbench-0.6.10/dbbench"

	sudo $PLOXD/build/src/ploxd/plox $DBBENCH sqlite --iter 2000 --threads 4
}


run_nginx()
{
	NGINX="nginx"
	CONFIG="$ROOT/configs/nginx.conf"

	sudo $NGINX -c "$CONFIG" -e "$ROOT/logs/error.log"
}

run_nginx_with_plox()
{
	NGINX=$(which nginx)
	CONFIG="$ROOT/configs/nginx.conf"

	sudo $PLOXD/build/src/ploxd/plox $NGINX -c "$CONFIG" -e "$ROOT/logs/error.log"
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
	# Need full path for PLOX
	REDIS=$(which redis-server)
	sudo $PLOXD/build/src/ploxd/plox $REDIS $ROOT/configs/redis.conf
}


run_redis_benchmark()
{
	ROOT=$(realpath "$(dirname "$0")/..")
	BENCH="redis-benchmark"
	$BENCH -h 127.0.0.1 -p 19999 -q -c 10 -n 50000 --csv
}


run_wrk() {
	ROOT=$(realpath "$(dirname "$0")/..")

	DIRBENCH="wrk"
	WRK="$ROOT/$DIRBENCH/wrk"

	$WRK -t 8 -c 16 -d 30s --latency "http://127.0.0.1:19999"
}
