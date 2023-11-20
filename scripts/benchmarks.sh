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
