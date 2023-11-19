#!/usr/bin/env bash

lighttpd_benchmark()
{

ROOT=$(realpath "$(dirname "$0")/..")
. $ROOT/scripts/util.sh

PLOXD=/usr/home/ryan/ploxd

mkdir -p $ROOT/out

OUTPUT=$ROOT/out/lighttpd.csv

touch $OUTPUT

kldload $PLOXD/kplox/kmod/plox.ko
$PLOXD/build/src/ploxd/ploxd &

run_lighttpd_with_plox

sleep 5

for ITER in {1..5}
do
  echo "Lighttpd-with-plox $ITER"
  VALUE=$(run_wrk | grep "Requests/sec" | awk -F':' '{print $2}')
  echo "plox, $VALUE," >> $OUTPUT
  sleep 3
done

kill -SIGINT `pgrep ploxd`
sleep 1
kill -SIGINT `pgrep ploxd`
sleep 1

run_lighttpd &

for ITER in {1..5}
do
  VALUE=$(run_wrk | grep "Requests/sec" | awk -F':' '{print $2}')
  echo "default, $VALUE," >> $OUTPUT
  sleep 3
done

kill -9 `pgrep lighttpd`

}

redis_benchmark()
{

ROOT=$(realpath "$(dirname "$0")/..")
. $ROOT/scripts/util.sh

PLOXD=/usr/home/ryan/ploxd

mkdir -p $ROOT/out

OUTPUT=$ROOT/out/redis.csv

touch $OUTPUT

kldload $PLOXD/kplox/kmod/plox.ko
$PLOXD/build/src/ploxd/ploxd &

run_redis_with_plox

sleep 5

for ITER in {1..5}
do
  echo "redis-benchmark $ITER"
  run_redis_benchmark >> $OUTPUT
done

kill -SIGINT `pgrep ploxd`
sleep 1
kill -SIGINT `pgrep ploxd`
sleep 1

run_redis &

sleep 5

for ITER in {1..5}
do
  echo "redis-benchmark $ITER"
  run_redis_benchmark >> $OUTPUT
done

kill -9 `pgrep redis`
}

redis_benchmark
