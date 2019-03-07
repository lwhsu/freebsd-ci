#!/bin/sh


JOB_BASE=`dirname $0`
cat ${JOB_BASE}/GENERIC-NFS | tee ${WORKSPACE}/src/sys/arm64/conf/GENERIC-NFS

env \
	JFLAG=${BUILDER_JFLAG} \
	TARGET=arm64 \
	TARGET_ARCH=aarch64 \
	SRCCONF=${WORKSPACE}/${JOB_BASE}/src.conf \
	sh -x ${WORKSPACE}/freebsd-ci/scripts/build/build-world-kernel-head.sh

