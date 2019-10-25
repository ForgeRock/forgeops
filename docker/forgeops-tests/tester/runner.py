import time
from requests import post
import os
import sys
from time import strftime, gmtime
import pytest
import urllib3
import logging
from config.ProductConfig import AMConfig, base_url

# Framework imports
urllib3.disable_warnings()
logger = logging.getLogger("flask_app")

def wait_for_products():
    """
    Waits for all products to be ready and configured. Testing service endpoints.
    TODO - Include other products. Currently only AM is checked.
    """
    ready = False

    headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
               'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}

    logger.info('Targetting cluster in {}'.format(base_url()))
    while not ready:
        print("Trying admin login to see if AM is ready")

        #if we're running smoke tests in our eng shared cluster, use the public endpoint
        if "smoke.iam.forgeops.com" in base_url():
            url = base_url() + "/am/json/authenticate"
            verify = True
        
        #assume we're running locally, talk to pod directly
        else: 
            url = 'http://am:80/am/json/authenticate'
            verify = False
        try:
            response = post(verify=verify, url=url, headers=headers, timeout=3)
            if response.status_code == 200:
                logger.info("Admin login successful, exiting loop...")
                return
            else:
                logger.info("Admin login failed, sleeping for 10 secs")
                time.sleep(10)
        except Exception as _e:
            logger.info("Exception when logging in, this is expected. Waiting for 10 secs")
            time.sleep(10)


def run(test_path = "tests/smoke", firstTimeExtraWait = False):
    wait_for_products()
    if firstTimeExtraWait:
        #Wait extra time before starting when running on first boot
        logger.info("AM is healthy. Waiting additional 60seconds to avoid race conditions during first boot")
        time.sleep(60)
    logger.info("Starting tests...")
    report_path = os.path.abspath(os.path.join('tester', 'reports'))
    if not os.path.exists(report_path):
        os.makedirs(report_path)
    else:
        if os.path.isfile(os.path.join(report_path, 'latest.html')):
            os.remove(os.path.join(report_path, 'latest.html'))

    html_report_name = 'forgeops_' + strftime("%Y-%m-%d_%H:%M:%S", gmtime()) + '_report.html'
    html_report_path = os.path.join(report_path, html_report_name)
    allure_report_path = os.path.join(report_path, 'allure-files')

    custom_args = '--html=%s --self-contained-html --alluredir=%s' % (html_report_path, allure_report_path)
    args = [test_path] + custom_args.split()
    pytest.main(args=args)

    latest_link = os.path.join(report_path, 'latest.html')
    if os.path.lexists(latest_link):
        os.unlink(latest_link)
    if os.path.exists(latest_link):
        os.remove(latest_link)
    os.symlink(html_report_name, latest_link)

    return



if __name__ == '__main__':
    run()


