#!/bin/sh

export TARGET=aarch64
export TARGET_ARCH=aarch64
export DEVICE_NAME=beaglebone

export USE_TEST_SUBR="
disable-dtrace-tests.sh
disable-zfs-tests.sh
run-kyua.sh
"

sh -x freebsd-ci/scripts/test/run-device-tests.sh
