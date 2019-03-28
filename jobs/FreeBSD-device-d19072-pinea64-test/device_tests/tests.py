# Either (or both) of these lists should be defined. 
# The lists should be iterables of functions as specified below.
to_run = []
panic_actions = []

def example_test(ch):
    # ch is the console handler
    # before running this function, the device has already been logged into.
    # ch->timeout is the boot timeout (default 5 minutes) otherwise every expect timeout is 1 minute.
    # ch->console is the Pexpect instance for running commands
    # ch-> device is the device instance. 
    # ch->device->name is the device name
    # ch->device->turn_on/turn_off are methods for controlling the power to the device.
    # ch->CMDLINE_RE is the regex for the commandline
    
    ch.sendline("cd test")
    ch.expect(ch.CMDLINE_RE)
    ch.sendline("make test")
    ch.expect(ch.CMDLINE_RE)
    ch.sendline("./app-link")
    ch.expect("foo:")
    ch.expect(ch.CMDLINE_RE)
    # DONE
    

def bt_on_panic(ch):
    # before running this function, the device panicked during boot
    ch.sendline("bt")

# You can add multiple functions to either list. The will be run in the order of the list. 
to_run.append(example_test)
panic_actions.append(bt_on_panic)
