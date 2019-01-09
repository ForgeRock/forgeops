# build for AWS Lambda
# author: # Tony Vattathil avattathil@gmail.com
# This program create an OpenSSL compatible keypair
#
from __future__ import print_function
import json
import requests
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend

'''
Generate Keys 
returns: private,public keypair
'''
def generate_pem(keysize):
    key = rsa.generate_private_key(backend=default_backend(), public_exponent=65537, key_size=keysize)
    pem = key.private_bytes(encoding=serialization.Encoding.PEM, 
                            format=serialization.PrivateFormat.TraditionalOpenSSL, 
                            encryption_algorithm=serialization.NoEncryption())
    pub = key.public_key().public_bytes(serialization.Encoding.OpenSSH, 
                                        serialization.PublicFormat.OpenSSH)
    private = pem.decode('utf-8')
    public = pub.decode('utf-8')
    return private, public
'''
Sends Response
input: sendResponse(event, context, responseStatus, responseData)
'''
def sendResponse(event, context, responseStatus, responseData):
    responseData['PEM'],responseData['PUB'] = generate_pem(2048)
    responseBody = {'Status': responseStatus,
                    'StackId': event['StackId'],
                    'RequestId': event['RequestId'],
                    'PhysicalResourceId': context.log_stream_name,
                    'Reason': 'For details see AWS CloudWatch LogStream: ' + context.log_stream_name,
                    'LogicalResourceId': event['LogicalResourceId'],
                    'Data': responseData}
    try:
        request = requests.put(event['ResponseURL'], data=json.dumps(responseBody))
        if request.status_code != 200:
            print (request.text)
            raise Exception('Error detected in [CFN RESPONSE != 200.')
        return
    except requests.exceptions.RequestException as err:
        print (err)
        raise

def handler(event, context):
    responseStatus = 'SUCCESS'
    responseData = {}
    if event['RequestType'] == 'Delete':
        sendResponse(event, context, responseStatus, responseData)
 
    responseData = {'Success': 'PASSED.'}
    sendResponse(event, context, responseStatus, responseData)
 
if __name__ == '__main__':
    handler('event', 'handler')
