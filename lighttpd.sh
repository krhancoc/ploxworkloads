#!/usr/bin/env bash
source syscalls.sh

DIRNAME="lighttpd-1.4.72"
LIGHTTPD="./$DIRNAME/src/lighttpd"
CONFIG="configs/lighttpd.conf"
DIRBENCH="wrk"
WRK="./$DIRBENCH/wrk"
LIBCOVERAGE="libcoverage/libcoverage.so"

make -C "libcoverage"
make -C $DIRNAME
gmake -C $DIRBENCH

for NUM in $COVERAGE
do
  echo "Coverage of $NUM"
  SYSCALL_TRACE_NUMBER=$NUM LD_PRELOAD=$LIBCOVERAGE $LIGHTTPD -f $CONFIG
  $WRK -t 6 -c 100 -d 5s --latency "http://127.0.0.1:19999"
  kill -9 $(pgrep lighttpd)
done

