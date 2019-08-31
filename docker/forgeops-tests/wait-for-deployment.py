import time

from requests import post


def wait_for_products():
    """
    Waits for all products to be ready and configured. Testing service endpoints.
    TODO - Include other products. Currently only AM is checked.
    """
    ready = False

    headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
               'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}

    while not ready:
        print("Trying admin login to see if AM is ready")

        try:
            response = post(verify=False, url='http://am:80/am/json/authenticate', headers=headers)
            if response.status_code is 200:
                print("Admin login successful, exiting...")
                return
            else:
                print("Admin login failed, sleeping for 10 secs")
                time.sleep(10)
        except Exception as e:
            print("Exception when logging in, this is expected. Waiting for 10 secs")
            time.sleep(10)


if __name__ == '__main__':
    wait_for_products()
