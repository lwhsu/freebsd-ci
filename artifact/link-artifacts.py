#!/usr/local/bin/python3

import sys
import os
import errno

from pathlib import Path
from os import path


JENKINS_ARTIFACT_BASEDIR = Path("/jenkins/artifact/snapshot")
WORKSPACE = os.environ["WORKSPACE"]
REVISION = "r" + os.environ['SVN_REVISION']
BRANCH = os.environ['FBSD_BRANCH']
TARGET = os.environ['FBSD_TARGET']
TARGET_ARCH = os.environ['FBSD_TARGET_ARCH']
LINK_TYPE = os.environ['LINK_TYPE']

def link_artifact_dir():
    artifact_dir = JENKINS_ARTIFACT_BASEDIR/BRANCH/REVISION/TARGET/TARGET_ARCH
    link_dir = JENKINS_ARTIFACT_BASEDIR/BRANCH/LINK_TYPE/TARGET/TARGET_ARCH
    
    artifact_dir.mkdir(parents=True, exist_ok=True)
    try:
        link_dir.symlink_to(artifact_dir)
    except OSError as e:
        if e.errno == errno.EEXIST:
            link_dir.unlink()
            link_dir.symlink_to(artifact_dir)

if __name__ == "__main__":
    link_artifact_dir()


