#!/usr/local/bin/python3 -u

import sys

from os import environ
from contextlib import suppress
from pexpect import spawn, run
from pexpect import EOF, TIMEOUT


class DevicePanic(Exception):
    def __init__(self, *args, **kwargs):
        if not (args or kwargs):
            args = ("Encountered a panic while trying to boot device.",)
        super().__init__(*args, **kwargs)

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
        self.panic_actions = set()
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
        print("Boot was successful. Running tests ...")
        failed_tests = 0
        num_tests = len(self.tests)
        for test in self.tests:
            print(f"> {test.__name__}")

            # Provides:
            # - device (name and power methods)
            # - console (for expect methods)
            # - boot timeout length
            resp = test(self)
            if resp is None:
                print(f"> Returned nothing. Assuming PASS.")
                print()
                continue
            else:
                if len(resp) != 2 or type(resp[0]) is not bool:
                    print(f"> Returned invalid response '{resp}'. Should have been of the form '[bool, str(msg)]'")
                    print()
                    failed_tests += 1
                    continue
                passed, msg = resp
                if not msg:
                    msg = ""
                else:
                    msg = f" with message '{str(msg)}'"
                if passed:
                    print("> PASS" + msg)
                else:
                    failed_tests += 1
                    print("> FAIL" + msg)
                print()
            # NOTE: A panic could happen after/during a test.
            # May want to check for panics after "login:"
        passed_tests = num_tests - failed_tests
        print(f"Done all tests. Passed ({passed_tests}/{num_tests}).")
        print("Powering off.")
        self.console.sendline("poweroff")
        # poweroff can take quite a while ...
        self.console.expect(r"Uptime: (?:\d+m)?\d+s", timeout=self.timeout)
        self.exit_console()
        return not bool(failed_tests)

    def run_tests(self):
        self.console = spawn("console", ["-f", self.device.name],
            timeout=ConsoleHandler.CMD_TIMEOUT,
            echo=False,
            logfile=self.device.logfile
        )
        self.device.turn_on()
        self.verify_console()
        passed_all = True
        # Special timeout for booting since it takes longer
        idx = self.console.expect_exact([
            "panic:",
            "login:"
        ], timeout=self.timeout)
        if idx == 0:
            self.console.expect_exact("db> ")
            # send some commands
            print("Panic was hit. Running panic actions ...")
            for panic_action in self.panic_actions:
                print(f"> {panic_action.__name__}")
                panic_action(self)
            print("Done all panic actions.")
            raise DevicePanic()
        else:
            passed_all = self.do_login()
        self.device.turn_off()
        return passed_all

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
        print("Loading tests ...")
        with suppress(ModuleNotFoundError):
            # Tests to run should be in a list 'to_run' in 'tests.py'
            # in the current directory.
            import tests
            print("Found tests.py")
            # Should provide 2 iterables that provide functions: (to_run and panic_actions)
            # to_run: iterable of functions to run after successful login.
            #         Should be used to send commands and verify they work on the device.
            # panic_actions: iterable of functions to run after a panic
            #                Should be used to get extra debugging information (i.e. show bt) from a panic.
            # each function should take a console handler object:
            # console_handler
            # ->tests - the list of tests
            # ->panic_actions - the list of panic actions
            # ->device - the device object (contains name, and power methods)
            # ->timeout - the  boot timeout
            # ->console - the pexpect instance
            if hasattr(tests, 'to_run'):
                console_handler.tests = tests.to_run
                print(f"Found tests.to_run which provided {len(console_handler.tests)} tests")
            if not console_handler.tests:
               print("Found no tests.to_run")
            if hasattr(tests, 'panic_actions'):
                console_handler.panic_actions = tests.panic_actions
                print(f"Found tests.panic_actions which provided {len(console_handler.panic_actions)} actions")
            if not console_handler.panic_actions:
               print("Found no tests.panic_actions")
        if not (console_handler.tests or console_handler.panic_actions):
            print("Running default boot and shutdown sequence.")
        # May raise timeout and EOF exceptions
        passed_all = console_handler.run_tests()
        print("All Done.")
        return int(not passed_all) # return 0 if passed_all otherwise 1

if __name__ == "__main__":
    sys.exit(main())
