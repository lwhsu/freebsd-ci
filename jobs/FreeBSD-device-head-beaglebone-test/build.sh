#!/bin/sh

export TARGET=arm64
export TARGET_ARCH=aarch64
export DEVICE=beaglebone

sh -x freebsd-ci/scripts/test/extract-artifacts.sh
sh -x freebsd-ci/scripts/test/run-device-tests.sh
