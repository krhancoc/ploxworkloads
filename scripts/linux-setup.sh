#!/usr/bin/env bash

ROOT=$(realpath "$(dirname "$0")/..")

cd $ROOT

sudo apt install wget cmake autoconf automake autotools pkgconf gcc libtool libevent-devel

# Lighttpd setup
wget https://download.lighttpd.net/lighttpd/releases-1.4.x/lighttpd-1.4.72.tar.gz
tar xzf lighttpd-1.4.72.tar.gz
rm lighttpd-1.4.72.tar.gz

# WRK Setup
git clone https://github.com/wg/wrk.git --depth=1
rm -rf wrk/.git

sudo apt-get install libevent-dev gcc-9 g++-9
wget https://launchpad.net/libmemcached/1.0/1.0.18/+download/libmemcached-1.0.18.tar.gz
tar zxf libmemcached-1.0.18.tar.gz
rm libmemcached-1.0.18.tar.gz
cd libmemcached-1.0.18
CXXFLAGS=-fpermissive CC=gcc-9 CXX=g++-9 ./configure --enable-memaslap
sudo make -j 8 install
cd -


# Nginx setup
sudo apt install nginx


# Redis Setup
sudo apt install redis

# Sqlite Setup
sudo apt install sqlite
sudo apt install go
wget https://github.com/sj14/dbbench/archive/refs/tags/v0.6.10.tar.gz
tar zxf v0.6.10.tar.gz
rm v0.6.10.tar.gz

