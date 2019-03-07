#!/bin/sh

_JENKINS_ARTIFACT_BASEDIR=/jenkins/artifact/snapshot

mv_artifacts () {
	cp -R ${ARTIFACT_PATH}/ ${_JENKINS_ARTIFACT_BASEDIR}
}

mv_artifacts
