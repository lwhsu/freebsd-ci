#!/bin/sh


JOB_BASE=`dirname $0`
cat ${JOB_BASE}/${CONF_NAME}-NFS | tee ${WORKSPACE}/src/sys/arm/conf/${CONF_NAME}-NFS

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=${FBSD_TARGET} \
	TARGET_ARCH=${FBSD_TARGET_ARCH} \
	SRCCONF=${WORKSPACE}/${JOB_BASE}/src.conf \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh

