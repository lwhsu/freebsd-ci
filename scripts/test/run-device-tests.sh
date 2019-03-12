#!/bin/sh
JOB_DIR=freebsd-ci/jobs/${JOB_NAME}
DEFAULT_TESTS_DIR=freebsd-ci/scripts/test/device_tests
TIMEOUT=300 # 5 minute timeout
DEVICE_PORT=cuaU0
TESTS_DIR=${JOB_DIR}/device_tests
cp -R ${DEFAULT_TESTS_DIR} .
cd device_tests
if [ -d ${TESTS_DIR} ]; then
	cp -R ${TESTS_DIR}/ .
fi
set +e
./test_device.exp ${DEVICE_NAME} ${DEVICE_PORT}
rc=$?
set -e
cd -

echo "return code = $rc"
devpowerctl turn_off ${DEVICE_NAME}

exit $rc
