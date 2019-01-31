#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Python Imports
import os
import sys
from time import strftime, gmtime
import pytest
import urllib3

# Framework imports

urllib3.disable_warnings()

# root_dir : computed using relative position from this file
root_dir = os.path.abspath(os.path.dirname(__file__))

# Insert lib folder (as very first lib directory - rank 0) to python path
sys.path.insert(0, os.path.join(root_dir, 'lib'))

# Insert config folder (rank 1) to python path
sys.path.insert(0, os.path.join(root_dir, 'config'))


def set_allure_environment_props(filename):
    # Get os environment properties as dictionary
    environment_properties = dict(os.environ)

    # Get properties that start with TESTS_ from environment.properties
    tests_properties = {}
    for key, value in environment_properties.items():
        if key.startswith("TESTS_"):
            tests_properties[key] = environment_properties[key]

    # Write properties to environment.properties file
    with open(filename, 'w') as file:
        for key, value in tests_properties.items():
            file.write('%s=%s\n' % (key, value))


if __name__ == '__main__':

    report_path = 'reports'
    if not os.path.exists(report_path):
        os.makedirs(report_path)

    html_report_name = 'forgeops_' + strftime("%Y-%m-%d_%H:%M:%S", gmtime()) + '_report.html'
    html_report_path = os.path.join(report_path, html_report_name)
    allure_report_path = os.path.join(report_path, 'allure-files')

    set_allure_environment_props(os.path.join(root_dir, report_path, 'environment.properties'))

    custom_args = '--html=%s --self-contained-html --alluredir=%s' % (html_report_path, allure_report_path)
    args = sys.argv + custom_args.split()
    res = pytest.main(args=args)

    latest_link = os.path.join(report_path, 'latest.html')
    if os.path.lexists(latest_link):
        os.unlink(latest_link)
    if os.path.exists(latest_link):
        os.remove(latest_link)
    os.symlink(html_report_name, latest_link)

    sys.exit(res)
