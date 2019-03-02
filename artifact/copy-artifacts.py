#!/usr/local/bin/python3

import sys
import os
import errno

from pathlib import Path
#from shutil import copytree
from distutils.dir_util import copy_tree 


JENKINS_ARTIFACT_BASEDIR = Path("/jenkins/artifact/snapshot")
WORKSPACE = ""
ARTIFACT_PATH = ""

def load_from_environ():
    WORKSPACE = os.environ["WORKSPACE"]
    ARTIFACT_PATH = os.environ["ARTIFACT_PATH"]

def copy_artifacts():
    workspace_artifacts = Path(f"{ARTIFACT_PATH}")
    copy_tree(str(workspace_artifacts.resolve()), str(JENKINS_ARTIFACT_BASEDIR.resolve()))

if __name__ == "__main__":
    load_from_environ()
    copy_artifacts()


