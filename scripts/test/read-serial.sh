#!/bin/sh


TIMEOUT=5400
TIMEOUT_EXPECT=$((${TIMOUT} - 60))
TIMEOUT_DEVICE=$((${TIMEOUT_EXPECT} -120))
DEVICE_PORT=/dev/cuaU0
RESULTS_LOG=${ARTIFACT_DEST}/boot.log

cat ${SERIAL_PORT} > ${ARTIFACT_DEST}/boot.log
export -c "set timeout ${TIMEOUT_EXPECT}; \
	spawn sudo /usr/bin/timeout -k 60 ${TIMEOUT_DEVICE} cat ${DEVICE_PORT} > ${LOG_RESULTS}; \
	expoect { eof }"
