# Either (or both) of these lists should be defined. 
# The lists should be iterables of functions as specified below.
to_run = []
panic_actions = []

class TestFailure(Exception):
    pass

def check_status(ch, msg):
    ch.console.sendline("echo $?")
    res = ch.expect(["0", r"\d+"])
    if res == 1:
        errno = ch.match.groups(0)
        raise TestFailure(f"Failed test with err {errno}: {msg}")

def test_tls_initial_exec(ch):
    try:
        ch.console.sendline("cd test")
        ch.console.expect(ch.CMDLINE_RE)
        check_status(ch, "Moving to test directory")

        ch.console.sendline("make test")
        ch.console.expect(ch.CMDLINE_RE)
        check_status(ch, "Making test (and running test)")

        ch.console.sendline("./app-link")
        res = ch.console.expect(["foo: 2016", ch.CMDLINE_RE])
        if res == 1:
            check_status(ch, "Did not get 'foo: 2016' when running './app-link'")
            return (False, "Unexpected result but no errno.")
        ch.console.expect(ch.CMDLINE_RE)
        # DONE
   except TestFailure as e:
       return (False, str(e))
   return (True, None)

to_run.append(example_test)
