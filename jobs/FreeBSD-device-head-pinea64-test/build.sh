#!/bin/sh

export TARGET=arm64
export TARGET_ARCH=aarch64
export DEVICE=pinea64

sh -x freebsd-ci/scripts/test/extract-artifacts.sh
#sh -x freebsd-ci/scripts/test/run-device-tests.sh

