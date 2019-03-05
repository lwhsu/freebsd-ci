#!/bin/sh

_JENKINS_ARTIFACT_BASEDIR=/jenkins/artifact/snapshot

mv_artifacts () {
	mv "${ARTIFACT_PATH}" "${_JENKINS_ARTIFACT_BASEDIR}"
}

mv_artifacts
