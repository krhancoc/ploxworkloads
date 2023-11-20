#!/usr/bin/env bash
#
ROOT=$(realpath "$(dirname "$0")/..")

source $ROOT/benchmarks.sh

redis_benchmark
lighttpd_benchmark
sqlite_benchmark
nginx_benchmark
memcached_benchmark


