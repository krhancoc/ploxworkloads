#!/usr/bin/env bash

check_java_version() {
    VERSION=`awk -F "." '{print $1}' <(awk -F " " '{print $2}' <(javac -version))`
    if [ "$VERSION" -ne "$1" ]; then
	echo "Java version $VERSION, required $1"
	echo "Install correct java or set JAVA_HOME"
	return 1
    fi

    return 0
}

ROOT=$(realpath "$(dirname "$0")/..")

check_java_version 19
RET=$?
if [ "$RET" -eq "1" ]; then
    echo "Bad Java Version"
    exit 1
fi

if [ ! -c /dev/kcov ]; then
    echo "KCOV device not present, kernel must have option KCOV set in kernel make options" >&2
    exit 1
fi

export BCPI=$ROOT/bcpi

if [ $# -ne 1 ]; then
  echo "Usage: $0 <KERNEL>" >&2
  exit 1
fi

# Pull BCPI
git clone ssh://vcs@review/source/bcpi.git bcpi

cd $BCPI
echo "Installing Ghidra"
./scripts/install-ghidra.sh

echo "Merging Debug Kernel and Kernel"
./scripts/merge-kernel.sh $1 ./kernel.merged

echo "Importing kernel"
./scripts/import-kernel-kcov.sh ./kernel.merged <(kldstat)

