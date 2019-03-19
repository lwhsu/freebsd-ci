#!/bin/sh

DIST_PACKAGES="base kernel tests"
TFTPROOT=/b/tftpboot
DESTDIR=${TFTPROOT}/${DEVICE}/install

# clean up destdir
sudo mkdir -p ${DESTDIR}
sudo chflags -R noschg ${DESTDIR}
sudo rm -rf ${DESTDIR}/*

# install files
for f in ${DIST_PACKAGES}
do
	sudo tar Jxf ${ARTIFACT_PATH}/${f}.txz -C ${DESTDIR}
done

sudo mkdir -p ${TFTPROOT}/dtb
sudo cp -r ${DESTDIR}/boot/dtb ${TFTPROOT}/dtb

# Create new fstab
cat <<- EOF | sudo tee ${DESTDIR}/etc/fstab
	#Custom /etc/fstab for FreeBSD NFS booting
	# Device 			Mountpoint	FSType	Options	Dump	Pass
	10.0.0.1:${DESTDIR}		/		nfs	rw	0	0
EOF

# Create new /boot/loader.conf
cat <<- EOF | sudo tee ${DESTDIR}/boot/loader.conf
	# Speed up serial communications
	boot_multicons="YES"
	boot_serial="YES"
	comconsole_speed="115200"
	# Disable autoboot timer and beastie display
	autoboot_delay="-1"
	beastie_disable="YES"
EOF

# Create new /etc/rc.conf
cat <<- EOF | sudo tee ${DESTDIR}/etc/rc.conf
	# Set hostname
	hostname=${DEVICE}-cidev
	# Disable sendmail
	sendmail_enable="NONE"
	sendmail_submit_enable="NO"
	sendmail_outbound_enable="NO"
	sendmail_msp_queue_enable="NO"
EOF
