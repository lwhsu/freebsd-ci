# Copyright (c) 2014, Craig Rodrigues <rodrigc@FreeBSD.org>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice unmodified, this list of conditions, and the following
#    disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#
#
# RUN KYUA TESTS INSIDE WITH BHYVE
#
# The following program::
#   (1) takes a an image
#   (2) boots it
#   (3) runs tests in /usr/tests
#
from __future__ import print_function
from optparse import OptionParser
import atexit
import getopt
import json
import os
import os.path
import pexpect
import sys
import subprocess
import fabric.api

test_config = None
test_config_file = None
sentinel_file = None

def usage(argv):
    print("Usage:")
    print("    %s -f [JSON config file]" % argv[0])


def main(argv):

    try:
        opts, args = getopt.getopt(sys.argv[1:], "f:")
    except getopt.GetoptError as err:
        sys.exit(2)

    global test_config
    global test_config_file

    for o, a in opts:
        if o == "-f":
            test_config_file = a
        else:
            assert False, "unhandled option"

    if test_config_file is None:
        usage(argv)
        sys.exit(1)

    config_file = open(test_config_file, "r")
    test_config = json.load(config_file)
    config_file.close()
    # checkpreReqBhyve() # No longer needed since serial connections are being used.
    runTest()

def runTest():
    global test_config
    global test_config_file

    # Serial configurations etc. can be handled by another python script.

    # Create the bridge interface if it does not exist.
    # Configure the bridge with an IP address.
    # ./serial_link.py <serial_port> <device> [<has_serial_controller>=0]
    serial_cmd = "./serial_link.py %s %s %s" % \
          (test_config['serial_port'], test_config['device'], test_config['has_serial_controller'])
    print(serial_cmd)
    serial_child = pexpect.spawn(serial_cmd)
    serial_child.logfile = sys.stdout
    serial_child.expect(pexpect.EOF, timeout=120)

    power_cmd = "./power.py restart %s" % \
          (test_config['device'])
    print(power_cmd)
    power_child1 = pexpect.spawn(power_cmd)
    power_child1.logfile = sys.stdout

    # Log into the VM via expect, and execute enough
    # commands to figure out the IP address.
    # TODO: MAy have to add a "open/link start/start" command here
    serial_child.expect(['login:'], timeout=1200)
    serial_child.sendline("root")
    serial_child.expect(['Password:'], timeout=1200)
    serial_child.sendline("test")
    serial_child.expect("# ")

    # Change the prompt to something more unique
    prompt = "kyuatestprompt # "
    serial_child.sendline("set prompt=\"%s\"" % (prompt))
    serial_child.expect(prompt)
    serial_child.expect(prompt)

    # Don't bother finding network information (Ethernet is being used for NFS)
    # serial_child.sendline("ifconfig %s | grep 'inet '" % (test_config['interface']))
    # serial_child.before = None
    # serial_child.after = None
    # i = serial_child.expect(['       inet ', prompt, pexpect.EOF])
    # ip_address = None
    # if i == 0:
    #     # matched "	inet 8.8.178.209 netmask 0xffffffe0 broadcast 8.8.178.223"
    #     i1 = serial_child.expect(['netmask ', prompt, pexpect.EOF])
    #     if i1 == 0:
    #        # matched "netmask 0xffffffe0 broadcast 8.8.178.223"
    #         ip_address = serial_child.before.strip()
    #         print("\nFound IP address: %s" % (ip_address))
    #         subprocess.call(["sed", "-i", "", "-e", "/%s/d" % (ip_address), known_hosts])

    # Execute commands over serial connection.
    serial_child.sendline("cd /usr/tests")
    serial_child.sendline("kya test")
    serial_child.sendline("kyua report --verbose --results-filter passed,skipped,xfail,broken,failed  --output test-report.txt")
    serial_child.sendline("kyua report-junit --output=test-report.xml")
    serial_child.sendline("shutdown -p now")

    # Turn off the Power

    power_cmd = "./power.py turn_off %s" % \
          (test_config['device'])
    print(power_cmd)
    power_child2 = pexpect.spawn(power_cmd)
    power_child2.logfile = sys.stdout

def checkpreReqBhyve():
    # Check if Bhyve module is loaded, and if we ran the script as superuser.
    # If not, silently kill the application.
    euid = os.geteuid()
    if euid != 0:
        raise EnvironmentError("this script need to be run as root")
    ret = os.system("kldload -n vmm")
    if ret != 0:
        raise EnvironmentError("missing vmm.ko")
    ret = os.system("kldload -n if_tap")
    if ret != 0:
        raise EnvironmentError("missing if_tap.ko")

def cleanup():
    os.system("rm -f %s" % (sentinel_file))

if __name__ == "__main__":
    atexit.register(cleanup)
    main(sys.argv)
