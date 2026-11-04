#!/usr/bin/env python3
"""Reads the report FUnit wrote (tests/funit) and says whether the run counts as passed. Standard library only.

  funit_report.py <funit-report-razi.json>

Exit code 0 only when the file exists, at least one test ran and every test that ran passed: a suite that did not start
leaves no report, and the game itself exits with 0 in some such cases.
"""
import json
import sys


def main():
    try:
        with open(sys.argv[1]) as file:
            tests = json.load(file)["results"]["tests"]
    except (IndexError, OSError, ValueError, KeyError) as error:
        sys.stderr.write("error: no usable FUnit report (%s)\n" % (error,))
        return 1
    if not tests:
        sys.stderr.write("error: FUnit ran no test\n")
        return 1
    bad = [test for test in tests if test.get("status") != "passed"]
    for test in bad:
        sys.stderr.write("FAILED %s: %s\n" % (test.get("name"), str(test.get("message", ""))[:600]))
    print("%d of %d tests passed" % (len(tests) - len(bad), len(tests)))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
