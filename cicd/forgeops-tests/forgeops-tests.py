"""
Main entry-point for forgeops testing suite.
"""
import argparse

from lib.JsonTestRunner import runner
from unittest import TestLoader, TestSuite

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--suite', help='Test suite to run (e.g tests/smoke)', required=True)
    args = parser.parse_args()
    suite_name = vars(args)['suite']

    tl = TestLoader()
    suite = TestSuite()

    try:
        suite.addTests(tl.discover(suite_name, pattern='*.py'))
    except ImportError:
        print("Suite cannot be found. Check if --suite points to folder with tests.")
        exit(0)
    runner = runner.JsonTestRunner(report_path="reports")
    results = runner.run(suite)
