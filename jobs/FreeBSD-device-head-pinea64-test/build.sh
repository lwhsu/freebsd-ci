#!/bin/sh

export TARGET=${FBSD_TARGET}
export TARGET_ARCH=${FBSD_TARGET_ARCH}
export DEVICE=${DEVICE_NAME}

sh -ex freebsd-ci/scripts/test/extract-artifacts.sh
sh -ex freebsd-ci/scripts/test/run-device-tests.sh

