#!/usr/bin/env bash

run_wrk() {
	DIRBENCH="wrk"
	WRK="$PWD/../$DIRBENCH/wrk"

	$WRK -t 8 -c 16 -d 30s --latency "http://127.0.0.1:19999"
}

run_redis()
{
	REDIS="redis-server"
	sudo $REDIS $ROOT/configs/redis.conf
}

run_redis_with_seccomp()
{
	# Need full path for PLOX
	REDIS=$(which redis-server)
	sudo $ROOT/sec/sec "redis" $REDIS $ROOT/configs/redis.conf
}

run_redis_benchmark()
{
	BENCH="redis-benchmark"
	$BENCH -h 127.0.0.1 -p 19999 -q -c 10 -n 50000 --csv
}

redis_benchmark()
{
	ROOT=$PWD/..

	mkdir -p $ROOT/out

	OUTPUT=$ROOT/out/redis-seccomp.csv

	touch $OUTPUT

	for ITER in {1..5}
	do
		run_redis

		sleep 3

		echo "redis-benchmark $ITER"
		run_redis_benchmark >> $OUTPUT
		echo "" >> $OUTPUT

		redis-cli -h 127.0.0.1 -p 19999 shutdown

		sleep 3

		rm $ROOT/scripts/dump.rdb
	done

	echo "PLOX" >> $OUTPUT
	for ITER in {1..5}
	do
		run_redis_with_seccomp

		sleep 3

		echo "redis-benchmark $ITER"
		run_redis_benchmark >> $OUTPUT
		echo "" >> $OUTPUT

    kill -9 `pgrep redis-server`
    
    sleep 3

		rm $ROOT/scripts/dump.rdb
	done

	chmod a+rw $OUTPUT
}



run_memaslap()
{
	MEMASLAP="memaslap"

	$MEMASLAP -s 127.0.0.1:19999 -t 30s --threads=4
}

run_memcached()
{
	MEMCACHED="memcached"
	sudo $MEMCACHED -u root -l 127.0.0.1 -p 19999 
}

run_memcached_with_seccomp()
{
  MEMCACHED=$(which memcached)
	sudo $ROOT/sec/sec "memcached" $MEMCACHED -u root -l 127.0.0.1 -p 19999 
}

memcached_benchmark()
{
	ROOT=$PWD/..
	. $ROOT/scripts/util.sh

	mkdir -p $ROOT/out

	OUTPUT=$ROOT/out/memcached-seccomp.csv

	touch $OUTPUT

	for ITER in {1..5}
	do
		run_memcached &

		sleep 5

		VALUE=$(run_memaslap | tail -n 1 | awk -F' ' '{print $7","$5","$9}')
		echo "default, $VALUE," >> $OUTPUT

		sleep 1

		kill -9 `pgrep memcached`

		sleep 2
	done

	for ITER in {1..5}
	do
		run_memcached_with_seccomp &

		sleep 5

		VALUE=$(run_memaslap | tail -n 1 | awk -F' ' '{print $7","$5","$9}')
		echo "plox, $VALUE," >> $OUTPUT
		sleep 1

		kill -9 `pgrep memcached`

	done
}



run_nginx()
{
	NGINX="nginx"
	CONFIG="$ROOT/configs/nginx.conf"

	sudo $NGINX -c "$CONFIG"
}

run_nginx_with_seccomp()
{
  NGINX=$(which nginx)
	CONFIG="$ROOT/configs/nginx.conf"

	sudo $ROOT/sec/sec "nginx" $NGINX -c "$CONFIG" 
}



run_lighttpd()
{
	LIGHTTPD="lighttpd"
	CONFIG="$PWD/../configs/lighttpd.conf"

	sudo $LIGHTTPD -f $CONFIG -D
}

run_lighttpd_with_seccomp()
{
  LIGHTTPD=$(which lighttpd)
	CONFIG="$PWD/../configs/lighttpd.conf"
  SECCOMP="$PWD/../configs/profile.json"

	sudo $ROOT/sec/sec "lighttpd" $LIGHTTPD -f $CONFIG -D
}

nginx_benchmark()
{
  ROOT=$PWD/..

	mkdir -p $ROOT/out

	OUTPUT=$ROOT/out/nginx-seccomp.csv
	touch $OUTPUT

	for ITER in {1..5}
	do
		run_nginx &

		sleep 5

		VALUE=$(run_wrk | grep "Requests/sec" | awk -F':' '{print $2}')
		echo "default, $VALUE," >> $OUTPUT
		sleep 3

		kill -9 `pgrep nginx`
	done

	for ITER in {1..5}
	do
		run_nginx_with_seccomp &

		sleep 5

		VALUE=$(run_wrk | grep "Requests/sec" | awk -F':' '{print $2}')
		echo "plox, $VALUE," >> $OUTPUT
		sleep 3

		kill -9 `pgrep nginx`
	done
}


lighttpd_benchmark()
{
  ROOT=$PWD/..

	mkdir -p $ROOT/out

	OUTPUT=$ROOT/out/lighttpd-seccomp.csv
	touch $OUTPUT

	for ITER in {1..5}
	do
		run_lighttpd &

		sleep 5

		VALUE=$(run_wrk | grep "Requests/sec" | awk -F':' '{print $2}')
		echo "default, $VALUE," >> $OUTPUT
		sleep 3

		kill -9 `pgrep lighttpd`
	done

	for ITER in {1..5}
	do
		run_lighttpd_with_seccomp &

		sleep 5

		VALUE=$(run_wrk | grep "Requests/sec" | awk -F':' '{print $2}')
		echo "plox, $VALUE," >> $OUTPUT
		sleep 3

		kill -9 `pgrep lighttpd`
	done
}

#redis_benchmark
#memcached_benchmark
#nginx_benchmark
lighttpd_benchmark
