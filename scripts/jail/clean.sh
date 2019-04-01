#!/bin/sh

. freebsd-ci/scripts/jail/jail.conf

echo "clean jail ${JNAME}"
if [ jls -j ${JNAME} ]; then
	sudo jexec ${JNAME} sh -c "find ${WORKSPACE_IN_JAIL} -d -not -user jenkins -flags +schg -exec chflags noschg {} \;"
	sudo jexec ${JNAME} sh -c "find ${WORKSPACE_IN_JAIL} -d -not -user jenkins -exec rm -rf {} \;"
	sudo jail -r ${JNAME}
fi

if [ ${BUILDER_NETIF} -a ${BUILDER_JAIL_IP6} ]; then
	sudo ifconfig ${BUILDER_NETIF} inet6 ${BUILDER_JAIL_IP6} -alias
fi
if [ ${BUILDER_NETIF} -a ${BUILDER_JAIL_IP4} ]; then
	sudo ifconfig ${BUILDER_NETIF} inet ${BUILDER_JAIL_IP4} -alias
fi

if [ -n "${MOUNT_REPO}" ]; then
	PATHS=""
	PATHS+=usr/${MOUNT_REPO#/}
	PATHS+=dev
	PATHS+=${WORKSPACE_IN_JAIL#/}
	for path in PATHS; do
		if [mount -p | grep -q ${JPATH}/${path} ]; then
			sudo umount ${JPATH}/${path}
		fi
	done
fi
if [ -d ${ZFS_PARENT}/${JNAME} ]; then
	sudo chflags -R noschg ${ZFS_PARENT}/${JNAME}
	sudo rm -rf ${ZFS_PARENT}/${JNAME}
fi
