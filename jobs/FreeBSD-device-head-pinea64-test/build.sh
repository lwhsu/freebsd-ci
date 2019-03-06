#!/bin/sh

export TARGET=arm64
export TARGET_ARCH=aarch64
export DEVICE=pinea64

export USE_TEST_SUBR="
disable-dtrace-tests.sh
disable-zfs-tests.sh
run-kyua.sh
"

#sh -x freebsd-ci/scripts/test/run-device-tests.sh
sh -x freebsd-ci/scripts/test/extract-artifacts.sh
sh -x freebsd-ci/scripts/read-serial.sh
