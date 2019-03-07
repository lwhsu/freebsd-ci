#!/bin/sh

JOB_DIR=freebsd-ci/jobs/${JOB_NAME}

TIMEOUT_MS=${BUILD_TIMEOUT:-5400000}
TIMEOUT=$((${TIMEOUT_MS} / 1000))
TIMEOUT_EXPECT=$((${TIMEOUT} - 60))

METADIR=meta
METAOUTDIR=meta-out
# Flow
# 0) Open serial connection with device
# TODO: Write serial controlling scripts

# 1) Power cycle device (using power scripts)
devpowerctl ${DEVICE_NAME} restart
# 2) Use serial port to check if device is running as expected
# Wait some time and then check if the last line is either an error line or login


# 3) Power off device and view logs

for i in `jot ${EXTRA_DISK_NUM}`; do
	truncate -s 128m disk${i}
	BHYVE_EXTRA_DISK_PARAM="${BHYVE_EXTRA_DISK_PARAM} -s $((i + 3)):0,ahci-hd,disk${i}"
done

# prepare meta disk to pass information to testvm
rm -fr ${METADIR}
mkdir ${METADIR}
cp -R ${JOB_DIR}/${METADIR}/ ${METADIR}/
for i in ${USE_TEST_SUBR}; do
	cp ${TEST_BASE}/subr/${i} ${METADIR}/
done
touch ${METADIR}/auto-shutdown
sh -ex ${TEST_BASE}/create-meta.sh

# run test VM image with bhyve
FBSD_BRANCH_SHORT=`echo ${FBSD_BRANCH} | sed -e 's,.*-,,'`
TEST_VM_NAME="testvm-${FBSD_BRANCH_SHORT}-${TARGET_ARCH}-${BUILD_NUMBER}"
sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy || true
sudo /usr/sbin/bhyveload -c stdio -m ${VM_MEM_SIZE} -d ${IMG_NAME} ${TEST_VM_NAME}
set +e
expect -c "set timeout ${TIMEOUT_EXPECT}; \
	spawn sudo /usr/bin/timeout -k 60 ${TIMEOUT_VM} /usr/sbin/bhyve \
	-c ${VM_CPU_COUNT} -m ${VM_MEM_SIZE} -A -H -P -g 0 \
	-s 0:0,hostbridge \
	-s 1:0,lpc \
	-s 2:0,ahci-hd,${IMG_NAME} \
	-s 3:0,ahci-hd,meta.tar \
	${BHYVE_EXTRA_DISK_PARAM} \
	-l com1,stdio \
	${TEST_VM_NAME}; \
        expect { eof }"
rc=$?
echo "bhyve return code = $rc"
sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy

# extract test result
sh -ex ${TEST_BASE}/extract-meta.sh
rm -f test-report.*
mv ${METAOUTDIR}/test-report.* .

rm -f ${IMG_NAME}
