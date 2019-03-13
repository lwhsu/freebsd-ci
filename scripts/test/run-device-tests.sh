#!/bin/sh
JOB_DIR=freebsd-ci/jobs/${JOB_NAME}
DEFAULT_TESTS_DIR=freebsd-ci/scripts/test/device_tests
TIMEOUT=300 # 5 minute timeout
TESTS_DIR=${JOB_DIR}/device_tests
cp -R ${DEFAULT_TESTS_DIR} .
if [ -d ${TESTS_DIR} ]; then
	cp -R ${TESTS_DIR}/ .
fi
cd device_tests
set +e
./test_device.exp
rc=$?
set -e
cd -

echo "return code = $rc"
if [ $rc -ne 0 ]; then
       	devpowerctl turn_off ${DEVICE}
fi
exit $rc
