#!/bin/sh


JOB_BASE=`dirname $0`
cat ${JOB_BASE}/${CONF_NAME} | tee ${WORKSPACE}/src/sys/arm64/conf/${CONF_NAME}
cat ${JOB_BASE}/GENERIC-NFS | tee ${WORKSPACE}/src/sys/arm64/conf/GENERIC-NFS

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=${FBSD_TARGET} \
	TARGET_ARCH=${FBSD_TARGET_ARCH} \
	SRCCONF=${WORKSPACE}/${JOB_BASE}/src.conf \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh

