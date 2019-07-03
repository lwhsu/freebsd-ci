#!/bin/sh

. freebsd-ci/scripts/jail/jail.conf

echo "clean jail ${JNAME}"

if [ -n "${MOUNT_OBJ}" ]; then
	_MOUNT_PATHS="${_MOUNT_PATHS} usr/${MOUNT_OBJ#/}"
	if [ -d ${JPATH}/${_MOUNT_PATH} ] && df ${JPATH}/${_MOUNT_PATH} | grep -q ${JPATH}/${_MOUNT_PATH}; then
		sudo umount ${JPATH}/${_MOUNT_PATH}
	fi
fi

if jls -j ${JNAME}; then
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

_MOUNT_PATHS="dev ${WORKSPACE_IN_JAIL#/}"
if [ -n "${MOUNT_REPO}" ]; then
	_MOUNT_PATHS="${_MOUNT_PATHS} usr/${MOUNT_REPO#/}"
fi
for _MOUNT_PATH in ${_MOUNT_PATHS}; do
	if [ -d ${JPATH}/${_MOUNT_PATH} ] && df ${JPATH}/${_MOUNT_PATH} | grep -q ${JPATH}/${_MOUNT_PATH}; then
		sudo umount ${JPATH}/${_MOUNT_PATH}
	fi
done

if [ -d ${ZFS_PARENT}/${JNAME} ]; then
	sudo chflags -R noschg ${ZFS_PARENT}/${JNAME}
	sudo rm -rf ${ZFS_PARENT}/${JNAME}
fi
