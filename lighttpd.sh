#!/usr/bin/env bash
source syscalls.sh

DIRNAME="lighttpd-1.4.72"
LIGHTTPD="./$DIRNAME/src/lighttpd"
CONFIG="configs/lighttpd.conf"
DIRBENCH="wrk"
WRK="./$DIRBENCH/wrk"
LIBCOVERAGE="libcoverage/libcoverage.so"

OUTPUT="out/lighttpd/"

sudo mkdir -p $OUTPUT
sudo chmod a+rwx $OUTPUT

sudo rm /tmp/kcov.log > /dev/null 2> /dev/null
kill -9 $(pgrep lighttpd) > /dev/null 2> /dev/null

for NUM in $COVERAGE
do
  echo "Coverage of $NUM"
  echo "SYSCALL_TRACE_NUMBER=$NUM LD_PRELOAD=$LIBCOVERAGE $LIGHTTPD -f $CONFIG"
  sudo SYSCALL_TRACE_NUMBER=$NUM LD_PRELOAD=$LIBCOVERAGE $LIGHTTPD -f $CONFIG > /dev/null
  $WRK -t 2 -c 10 -d 5s --latency "http://127.0.0.1:19999" > /dev/null
  kill -9 $(pgrep lighttpd)
  sudo mkdir -p "$OUTPUT/$NUM"
  sudo chmod a+rwx "$OUTPUT/$NUM"
  mv "/tmp/kcov.log" "$OUTPUT/$NUM/"
  sudo chmod a+rw "$OUTPUT/$NUM/kcov.log"
  sudo rm -rf "logs/*"
done

