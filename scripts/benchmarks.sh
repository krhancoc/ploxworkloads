#!/usr/bin/env bash

lighttpd_benchmark()
{
	ROOT=$(realpath "$(dirname "$0")/..")
	. $ROOT/scripts/util.sh

	PLOXD=/usr/home/ryan/ploxd

	mkdir -p $ROOT/out

	OUTPUT=$ROOT/out/lighttpd.csv

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
		kldload $PLOXD/kplox/kmod/plox.ko
		$PLOXD/build/src/ploxd/ploxd &

		run_lighttpd_with_plox

		sleep 5

		echo "Lighttpd-with-plox $ITER"
		VALUE=$(run_wrk | grep "Requests/sec" | awk -F':' '{print $2}')
		echo "plox, $VALUE," >> $OUTPUT
		sleep 3

		kill -SIGINT `pgrep ploxd`
		sleep 1
		kill -SIGINT `pgrep ploxd`
		sleep 1

		kldunload plox.ko
	done
}

memcached_benchmark()
{
	ROOT=$(realpath "$(dirname "$0")/..")
	. $ROOT/scripts/util.sh

	PLOXD=/usr/home/ryan/ploxd

	mkdir -p $ROOT/out

	OUTPUT=$ROOT/out/memcached.csv

	touch $OUTPUT

	for ITER in {1..10}
	do
		run_memcached &

		sleep 5

		VALUE=$(run_memaslap | tail -n 1 | awk -F' ' '{print $7","$5","$9}')
		echo "default, $VALUE," >> $OUTPUT

		sleep 1

		kill -9 `pgrep memcached`

		sleep 2
	done

	for ITER in {1..10}
	do
		kldload $PLOXD/kplox/kmod/plox.ko
		$PLOXD/build/src/ploxd/ploxd &

		run_memcached_with_plox

		sleep 5

		VALUE=$(run_memaslap | tail -n 1 | awk -F' ' '{print $7","$5","$9}')
		echo "plox, $VALUE," >> $OUTPUT
		sleep 1

		kill -9 `pgrep memcached`

		kill -SIGINT `pgrep ploxd`
		sleep 1
		kill -SIGINT `pgrep ploxd`
		sleep 1

		kldunload plox.ko
	done
}

nginx_benchmark()
{
	ROOT=$(realpath "$(dirname "$0")/..")
	. $ROOT/scripts/util.sh

	PLOXD=/usr/home/ryan/ploxd

	mkdir -p $ROOT/out

	OUTPUT=$ROOT/out/nginx.csv

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
		kldload $PLOXD/kplox/kmod/plox.ko
		$PLOXD/build/src/ploxd/ploxd &

		run_nginx_with_plox

		sleep 5

		VALUE=$(run_wrk | grep "Requests/sec" | awk -F':' '{print $2}')
		echo "plox, $VALUE," >> $OUTPUT

		sleep 1

		kill -9 `pgrep nginx`

		sleep 1

		kill -SIGINT `pgrep ploxd`
		sleep 1
		kill -SIGINT `pgrep ploxd`
		sleep 1

		kldunload plox.ko
	done
}

redis_benchmark()
{
	ROOT=$(realpath "$(dirname "$0")/..")
	. $ROOT/scripts/util.sh

	PLOXD=/usr/home/ryan/ploxd

	mkdir -p $ROOT/out

	OUTPUT=$ROOT/out/redis.csv

	touch $OUTPUT

	for ITER in {1..5}
	do
		run_redis

		sleep 5

		echo "redis-benchmark $ITER"
		run_redis_benchmark >> $OUTPUT
		echo "" >> $OUTPUT

		redis-cli -h 127.0.0.1 -p 19999 shutdown

		sleep 5

		rm $ROOT/scripts/dump.rdb
	done

	echo "PLOX" >> $OUTPUT
	for ITER in {1..5}
	do
		kldload $PLOXD/kplox/kmod/plox.ko

		$PLOXD/build/src/ploxd/ploxd &

		run_redis_with_plox

		sleep 5

		echo "redis-benchmark $ITER"
		run_redis_benchmark >> $OUTPUT
		echo "" >> $OUTPUT

		redis-cli -h 127.0.0.1 -p 19999 shutdown

		sleep 5

		kill -SIGINT `pgrep ploxd`
		sleep 1
		kill -SIGINT `pgrep ploxd`
		sleep 1

		rm $ROOT/scripts/dump.rdb
		kldunload plox.ko
	done

	chmod a+rw $OUTPUT

}

sqlite_benchmark()
{
	ROOT=$(realpath "$(dirname "$0")/..")
	. $ROOT/scripts/util.sh

	PLOXD=/usr/home/ryan/ploxd

	mkdir -p $ROOT/out

	OUTPUT=$ROOT/out/sqlite.csv

	touch $OUTPUT

	for ITER in {1..5}
	do
		echo "Default - $ITER"
		run_sqlite >> $OUTPUT
		echo "" >> $OUTPUT
		rm dbbench.sqlite*
	done

	echo "PLOX" >> $OUTPUT

	for ITER in {1..5}
	do
		echo "PLOX - $ITER"
		build_kplox > /dev/null

		kldload $PLOXD/kplox/kmod/plox.ko

		$PLOXD/build/src/ploxd/ploxd >> $OUTPUT &

		run_sqlite_with_plox

		# Hack for now
		sleep 60

		echo "" >> $OUTPUT

		kill -SIGKILL `pgrep ploxd`

		sleep 1

		kldunload plox.ko

		rm dbbench.sqlite*
		sleep 1
	done

	echo "PLOX" >> $OUTPUT

	for ITER in {1..5}
	do
		echo "PLOX - $ITER"
		build_kplox "-DDISABLE_READ=1 -DDISABLE_WRITE=1" > /dev/null

		kldload $PLOXD/kplox/kmod/plox.ko

		$PLOXD/build/src/ploxd/ploxd >> $OUTPUT &

		run_sqlite_with_plox

		# Hack for now
		sleep 60

		echo "" >> $OUTPUT

		kill -SIGKILL `pgrep ploxd`

		sleep 1

		kldunload plox.ko

		rm dbbench.sqlite*
		sleep 1
	done

}

redis_dtrace()
{
	ROOT=$(realpath "$(dirname "$0")/..")
	. $ROOT/scripts/util.sh

	PLOXD=/usr/home/ryan/ploxd

	mkdir -p $ROOT/out

	kldload $PLOXD/kplox/kmod/plox.ko

	$PLOXD/build/src/ploxd/ploxd &

	dtrace -s $PLOXD/kplox/scripts/plox.d -o dtrace.out &

	run_redis_with_plox

	sleep 5

	run_redis_benchmark > /tmp/output

	redis-cli -h 127.0.0.1 -p 19999 shutdown

	sleep 5

	kill -SIGINT `pgrep dtrace`

	kill -SIGINT `pgrep ploxd`
	sleep 1
	kill -SIGINT `pgrep ploxd`
	sleep 1

	rm $ROOT/scripts/dump.rdb
	kldunload plox.ko

	echo "RESULTS" >> dtrace.out
	cat dtrace.out /tmp/output > $ROOT/out/redis.dtrace
	rm dtrace.out	
	rm /tmp/output
}

sqlite_dtrace()
{
	ROOT=$(realpath "$(dirname "$0")/..")
	. $ROOT/scripts/util.sh

	PLOXD=/usr/home/ryan/ploxd

	mkdir -p $ROOT/out

	echo "PLOX - $ITER"

	kldload $PLOXD/kplox/kmod/plox.ko

	$PLOXD/build/src/ploxd/ploxd  > /tmp/output &

	run_sqlite_with_plox

	dtrace -s $PLOXD/kplox/scripts/plox.d -o dtrace.out &

	# Hack for now
	sleep 30

	kill -SIGINT `pgrep dtrace`

	sleep 5

	kill -SIGKILL `pgrep ploxd`

	sleep 1

	kldunload plox.ko

	rm dbbench.sqlite*
	sleep 1

	echo "RESULTS" >> dtrace.out
	cat dtrace.out /tmp/output > $ROOT/out/sqlite.dtrace
	rm dtrace.out	
	rm /tmp/output
}

memcached_dtrace()
{
	ROOT=$(realpath "$(dirname "$0")/..")
	. $ROOT/scripts/util.sh

	PLOXD=/usr/home/ryan/ploxd

	mkdir -p $ROOT/out

	kldload $PLOXD/kplox/kmod/plox.ko
	$PLOXD/build/src/ploxd/ploxd &

	run_memcached_with_plox

	sleep 5

	dtrace -s $PLOXD/kplox/scripts/plox.d -o dtrace.out &

	run_memaslap > /tmp/output

	kill -9 `pgrep memcached`

	kill -SIGINT `pgrep dtrace`

	kill -SIGINT `pgrep ploxd`
	sleep 1
	kill -SIGINT `pgrep ploxd`
	sleep 1

	kldunload plox.ko

	echo "RESULTS" >> dtrace.out
	cat dtrace.out /tmp/output > $ROOT/out/memcached.dtrace

	rm dtrace.out
	rm /tmp/output
}
