"""
Main entry-point for forgeops testing suite.
"""
import argparse
import os
from time import strftime, gmtime


from unittest import TestLoader, TestSuite
from HtmlTestRunner import HTMLTestRunner


def consolidate_reports():
    """
    Workaround for reports being separated by suite. For now we want only one consolidated report.
    """
    report_name = 'forgeops_' + strftime("%Y-%m-%d_%H:%M:%S", gmtime()) + '_report.html'
    report = ''
    for filename in os.listdir('reports/'):
        if not filename.startswith('forgeops_'):
            with open(os.path.join('reports', filename), 'r') as f:
                report += f.read()
            os.remove(os.path.join('reports', filename))

    with open(os.path.join('reports', report_name), 'w') as f:
        f.write(report)
    with open(os.path.join('reports', "latest.html"), 'w') as f:
        f.write(report)


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
    runner = HTMLTestRunner(output=".")
    results = runner.run(suite)
    consolidate_reports()

