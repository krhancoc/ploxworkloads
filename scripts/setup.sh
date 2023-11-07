#!/usr/bin/env bash

ROOT=$(realpath "$(dirname "$0")/..")

cd $ROOT

# Lighttpd setup
wget https://download.lighttpd.net/lighttpd/releases-1.4.x/lighttpd-1.4.72.tar.gz
tar xzf lighttpd-1.4.72.tar.gz
rm lighttpd-1.4.72.tar.gz

# WRK Setup
git clone https://github.com/wg/wrk.git --depth=1
rm -rf wrk/.git

# Memcached Setup
MCACHED="libmemcached-1.0.18"
wget https://launchpad.net/libmemcached/1.0/1.0.18/+download/libmemcached-1.0.18.tar.gz
tar xzf $MCACHED.tar.gz
rm $MCACHED.tar.gz
cd $MCACHED
patch -p1 <../$MCACHED.patch
sudo pkg install memcached


# Nginx setup
sudo pkg install nginx


# Redis Setup
sudo pkg install redis

# Sqlite Setup
sudo pkg install sqlite
sudo pkg install go
wget https://github.com/sj14/dbbench/archive/refs/tags/v0.6.10.tar.gz
tar zxf v0.6.10.tar.gz
rm v0.6.10.tar.gz

