#!/bin/sh

JOB_BASE=`dirname $0`
cat ${JOB_BASE}/${CONF_NAME}-NFS | tee ${WORKSPACE}/src/sys/arm64/conf/${CONF_NAME}-NFS

JFLAG=${BUILDER_JFLAG}
TARGET=${FBSD_TARGET}
TARGET_ARCH=${FBSD_TARGET_ARCH}
SRCCONF=${WORKSPACE}/${JOB_BASE}/src.conf

## common script

set -ex

if [ ! -n ${MOUNT_OBJ} ]; then
	export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
	rm -fr ${MAKEOBJDIRPREFIX}
else
	export MAKEOBJDIRPREFIX=/usr/${MOUNT_OBJ}
fi

MAKECONF=${MAKECONF:-/dev/null}
SRCCONF=${SRCCONF:-/dev/null}

cd /usr/src

sudo make -j ${JFLAG} -DNO_CLEAN \
	kernel-toolchain \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}
sudo make -j ${JFLAG} -DNO_CLEAN \
	buildkernel \
	TARGET=${TARGET} \
	TARGET_ARCH=${TARGET_ARCH} \
	__MAKE_CONF=${MAKECONF} \
	SRCCONF=${SRCCONF}

cd /usr/src/release

sudo make clean
sudo mkdir -p /usr/obj/usr/src/${TARGET}.${TARGET_ARCH}/release
sudo fetch https://artifact.ci.freebsd.org/snapshot/head/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}/base.txz \
	-o /usr/obj/usr/src/${TARGET}.${TARGET_ARCH}/release/base.txz
sudo touch /usr/obj/usr/src/${TARGET}.${TARGET_ARCH}/release/base.txz
sudo make -DNOPORTS -DNOSRC -DNODOC packagesystem \
	TARGET=${TARGET} TARGET_ARCH=${TARGET_ARCH} \
	MAKE="make -DDB_FROM_SRC __MAKE_CONF=${MAKECONF} SRCCONF=${SRCCONF}"

ARTIFACT_DEST=artifact/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
sudo mkdir -p ${ARTIFACT_DEST}
sudo mv /usr/obj/usr/src/${TARGET}.${TARGET_ARCH}/release/*.txz ${ARTIFACT_DEST}
sudo mv /usr/obj/usr/src/${TARGET}.${TARGET_ARCH}/release/MANIFEST ${ARTIFACT_DEST}

echo "r${SVN_REVISION}" | sudo tee ${ARTIFACT_DEST}/revision.txt

cat <<- EOF | sudo tee ${ARTIFACT_DEST}/trigger.property
	SVN_REVISION=${SVN_REVISION}
EOF
