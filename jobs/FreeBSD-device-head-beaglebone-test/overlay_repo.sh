#!/bin/sh

: ${DIST_PACKAGES:="base kernel tests"}
: ${TFTPROOT:="/b/tftpboot"}
: ${DESTDIR:="${TFTPROOT}/${DEVICE}/install"}
GITHUB_REPO=https://github.com/dumbbell/test-tls-initial-exec

git clone ${GITHUB_REPO} test
sudo mv test ${DESTDIR}/root
