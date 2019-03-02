#!/bin/sh

set -ex

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}

MAKECONF=${MAKECONF:-/dev/null}
SRCCONF=${SRCCONF:-/dev/null}
SHAREMK=${SHAREMK:-/usr/src/share/mk}

cd /usr/src

BUILDENV=`make TARGET_ARCH=${TARGET_ARCH} buildenvvars`
BUILDENV="${BUILDENV} SRCCONF=${SRCCONF} __MAKE_CONF=${MAKECONF}"

ARTIFACT_DEST=artifact/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
# Build EFI
cd stand

eval $BUILDENV make -j ${JFLAG} -m $SHAREMK obj
eval $BUILDENV make -j ${JFLAG} -m $SHAREMK clean
eval $BUILDENV make -j ${JFLAG} -m $SHAREMK depend
eval $BUILDENV make -j ${JFLAG} -m $SHAREMK all

cd efi/boot1

eval $BUILDENV make -j ${JFLAG} DESTDIR=${ARTIFACT_DEST} BINDIR=boot MK_MAN=no -m $SHAREMK install


