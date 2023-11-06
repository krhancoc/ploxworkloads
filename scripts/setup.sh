#!/usr/bin/env bash

ROOT=$(realpath "$(dirname "$0")")

cd $ROOT

wget https://download.lighttpd.net/lighttpd/releases-1.4.x/lighttpd-1.4.72.tar.gz
tar xzf lighttpd-1.4.72.tar.gz
rm lighttpd-1.4.72.tar.gz

git clone https://github.com/wg/wrk.git --depth=1
rm -rf wrk/.git
