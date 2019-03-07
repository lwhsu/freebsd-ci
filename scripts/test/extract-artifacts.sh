#!/bin/sh

DIST_PACKAGES="base kernel tests"
DESTDIR=/b/tftpboot/${DEVICE}/install

for f in ${DIST_PACKAGES}
do
	tar Jxf ${ARTIFACTS_DIR}/${f}.txz -C ${DESTDIR}
done

cat > ${DESTDIR}/etc/fstab <<- EOF
	#Custom /etc/fstab for FreeBSD NFS booting
	# Device 			Mountpoint	FSType	Options	Dump	Pass
	10.0.0.1:${DESTDIR}		/		nfs	rw	0	0
EOF
