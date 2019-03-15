#!/usr/local/bin/python3

import sys

from os import environ
from contextlib import suppress
from pexpect import spawn, run
from pexpect import EOF, TIMEOUT


class DevicePowerError(Exception):
    def __init__(self, operation, device_name, *args, **kwargs):
        message = f"Failed to do '{operation}' for '{device_name}'"
        super().__init__(message, *args, **kwargs)

class DeviceHandler:
    def __init__(self, name, logfile):
        self.name = name
        self.logfile =logfile

    def turn_on(self):
        _, status = run(f"devpowerctl restart {self.name}",
            withexitstatus=1
        )
        if status != 0:
            raise DevicePowerError("restart", self.name)

    def turn_off(self):
        _, status = run(f"devpowerctl turn_off {self.name}",
            withexitstatus=1
        )
        if status != 0:
            raise DevicePowerError("turn_off", self.name)

    def handle_err(self, err):
        print(err, file=self.logfile)
        sys.exit(1)

class ConsoleError(Exception):
    pass

class ConsoleHandler(object):
    """Handles communicating with the console"""
    CMD_TIMEOUT = 60
    CMDLINE_RE = r"root@(?:\w+-cidev)?:"

    def __init__(self, device, timeout=300):
        self.tests = set()
        self.device = device
        self.timeout = timeout
        self.console = None

    def verify_console(self):
        idx = self.console.expect_exact([
            "[connected]",
            "console is down"
        ])
        if idx == 1:
            self.exit_console()
            self.console.expect(EOF)
            raise ConsoleError("serial connection is down")

    def exit_console(self):
        self.console.sendcontrol("e")
        self.console.send("c.")

    def do_login(self):
        self.console.sendline("root")
        self.console.expect(ConsoleHandler.CMDLINE_RE)
        for test in self.tests:
            # Provides:
            # - device (name and power methods)
            # - console (for expect methods)
            # - boot timeout length
            test(self)
        self.console.sendline("poweroff")
        # poweroff can take quite a while ...
        self.console.expect(r"Uptime: (?:\d+m)?\d+s", timeout=self.timeout)
        self.exit_console()

    def run_tests(self):
        self.console = spawn("console", ["-f", self.device.name],
            timeout=ConsoleHandler.CMD_TIMEOUT,
            echo=False,
            logfile=self.device.logfile
        )
        self.device.turn_on()
        self.verify_console()
        # Special timeout for booting since it takes longer
        idx = self.console.expect_exact([
            "hit [Enter] to boot or any other key to stop",
            "login:"
        ], timeout=self.timeout)
        if idx == 0:
            self.console.send("\r\n")
            self.console.expect("login:")
        self.do_login()
        self.device.turn_off()

def err(msg):
    print(msg, file=sys.stderr)
    sys.exit(1)

def get_env():
    if "DEVICE" not in environ:
        err("Invalid Usage: 'DEVICE' environment variable was not defined")

    boot_timeout = 300
    if "TIMEOUT" in environ:
        boot_timeout = int(environ["TIMEOUT"])

    device = environ["DEVICE"]
    return device, boot_timeout

def main():
    device, boot_timeout = get_env()
    with open(f"{device}.boot.log", "wb") as logfile:
        device_handler = DeviceHandler(device, logfile)
        console_handler = ConsoleHandler(device_handler, timeout=boot_timeout)
        with suppress(ModuleNotFoundError):
            # Tests to run should be in a list 'to_run' in 'tests.py'
            # in the current directory.
            from tests import to_run
            console_handler.tests = to_run
        # May raise timeout and EOF exceptions
        console_handler.run_tests()

if __name__ == "__main__":
    main()
