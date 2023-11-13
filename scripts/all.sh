#!/usr/bin/env bash
#
ROOT=$(realpath "$(dirname "$0")/..")

./scripts/lighttpd.sh
./scripts/memcached.sh
./scripts/redis.sh
./scripts/sqlite.sh
#./scripts/nginx.sh
