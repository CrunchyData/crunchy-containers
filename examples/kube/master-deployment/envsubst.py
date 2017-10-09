#!/usr/bin/env python

import os
import sys

def main():
    for line in sys.stdin:
        sys.stdout.write(os.path.expandvars(line))
    sys.stdout.flush()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        pass
