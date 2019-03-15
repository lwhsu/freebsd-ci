#!/usr/local/bin/python3
import sys

from os import environ

def main():
    if "DEVICE" not in environ:
        print("Invalid Usage: 'DEVICE' environment variable was not defined.", file=sys.stderr)
        sys.exit(1)
    with open(f"{environ['DEVICE']}.boot.log") as logfile:
        print("Skipped boot for {environ['DEVICE']}", file=logfile)

if __name__ == "__main__":
    main()
