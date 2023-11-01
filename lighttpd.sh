#!/usr/bin/env bash
source syscalls.sh

DIRNAME="lighttpd-1.4.72"
LIGHTTPD="./$DIRNAME/src/lighttpd"
CONFIG="configs/lighttpd.conf"
DIRBENCH="wrk"
WRK="./$DIRBENCH/wrk"
LIBCOVERAGE="libcoverage/libcoverage.so"

OUTPUT="out/lighttpd/"

mkdir -p $OUTPUT

sudo rm /tmp/kcov.log

for NUM in $COVERAGE
do
  echo "Coverage of $NUM"
  sudo SYSCALL_TRACE_NUMBER=$NUM LD_PRELOAD=$LIBCOVERAGE $LIGHTTPD -f $CONFIG
  $WRK -t 6 -c 100 -d 10s --latency "http://127.0.0.1:19999"
  kill -9 $(pgrep lighttpd)
  mkdir -p $OUTPUT/$NUM
  sudo mv /tmp/kcov.log $OUTPUT/$NUM/pc.log
  sudo chmod a+rw $OUTPUT/$NUM/pc.log
  sudo rm -rf logs/*
done

