#!/bin/sh

: ${TFTPROOT:="/b/tftpboot"}
: ${DESTDIR:="${TFTPROOT}/${DEVICE}/install"}
JOB_BASE=`dirname $0`

# Compile DTSO
cp ${WORKSPACE}/${JOB_BASE}/am335x-boneblack-cpsw.dtso .
MACHINE=arm dtc -O dtb -o am335x-boneblack-cpsw.dtbo -b 0 -@ am335x-boneblack-cpsw.dtso
sudo mkdir -p ${DESTDIR}/boot/dtbo
sudo mv am335x-boneblack-cpsw.dtbo ${DESTDIR}/boot/dtbo

# Use overlay
sudo sysrc -f ${DESTDIR}/boot/loader.conf fdt_overlays+=",/boot/dtbo/am335x-boneblack-cpsw.dtbo"
