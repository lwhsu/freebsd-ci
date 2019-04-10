#!/bin/sh
JOB_DIR=freebsd-ci/jobs/${JOB_NAME}
DEFAULT_TESTS_DIR=freebsd-ci/scripts/test/device_tests
TIMEOUT=300 # 5 minute timeout
TESTS_DIR=${JOB_DIR}/device_tests
# remove current device tests
rm -rf device_tests
# copy in default device tests
cp -R ${DEFAULT_TESTS_DIR} .
if [ -d ${TESTS_DIR} ]; then
	# copy in job specific tests
	cp -R ${TESTS_DIR}/ device_tests/
fi
# run tests
cd device_tests
set +e
./test_device.py
rc=$?
set -e
cd -

echo "return code = $rc"
if [ $rc -ne 0 ]; then
       	devpowerctl turn_off ${DEVICE}
fi
exit $rc
