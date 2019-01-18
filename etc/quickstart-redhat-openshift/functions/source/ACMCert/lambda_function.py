import json
import logging
import boto3
import cfnresponse
import time
import re


acm_client = boto3.client('acm')
r53_client = boto3.client('route53')
lambda_client = boto3.client('lambda')
logs_client = boto3.client('logs')


def handler(event, context):
    print('Received event: %s' % json.dumps(event))
    status = cfnresponse.SUCCESS
    physical_resource_id = None
    data = {}
    reason = None
    try:
        if event['RequestType'] == 'Create':
            token = ''.join(ch for ch in str(event['StackId'] + event['LogicalResourceId']) if ch.isalnum())
            token = token[len(token)-32:]
            if len(event['ResourceProperties']['HostNames']) > 1:
                arn = acm_client.request_certificate(
                    ValidationMethod='DNS',
                    DomainName=event['ResourceProperties']['HostNames'][0],
                    SubjectAlternativeNames=event['ResourceProperties']['HostNames'][1:],
                    IdempotencyToken=token
                )['CertificateArn']
            else:
                arn = acm_client.request_certificate(
                    ValidationMethod='DNS',
                    DomainName=event['ResourceProperties']['HostNames'][0],
                    IdempotencyToken=token
                )['CertificateArn']
            physical_resource_id = arn
            logging.info("certificate arn: %s" % arn)
            rs = {}
            while True:
                try:
                    for d in acm_client.describe_certificate(CertificateArn=arn)['Certificate']['DomainValidationOptions']:
                        rs[d['ResourceRecord']['Name']] = d['ResourceRecord']['Value']
                    break
                except KeyError:
                    if (context.get_remaining_time_in_millis() / 1000.00) > 20.0:
                        print('waiting for ResourceRecord to be available')
                        time.sleep(15)
                    else:
                        logging.error('timed out waiting for ResourceRecord')
                        status = cfnresponse.FAILED
                    time.sleep(15)
            rs = [{'Action': 'CREATE', 'ResourceRecordSet': {'Name': r, 'Type': 'CNAME', 'TTL': 600,'ResourceRecords': [{'Value': rs[r]}]}} for r in rs.keys()]
            try:
                r53_client.change_resource_record_sets(HostedZoneId=event['ResourceProperties']['HostedZoneId'], ChangeBatch={'Changes': rs})
            except Exception as e:
                if not str(e).endswith('but it already exists'):
                    raise
            while 'PENDING_VALIDATION' in [v['ValidationStatus'] for v in acm_client.describe_certificate(CertificateArn=arn)['Certificate']['DomainValidationOptions']]:
                print('waiting for validation to complete')
                if (context.get_remaining_time_in_millis() / 1000.00) > 20.0:
                    time.sleep(15)
                else:
                    logging.error('validation timed out')
                    status = cfnresponse.FAILED
            for r in [v for v in acm_client.describe_certificate(CertificateArn=arn)['Certificate']['DomainValidationOptions']]:
                if r['ValidationStatus'] != 'SUCCESS':
                    logging.debug(r)
                    status = cfnresponse.FAILED
                    reason = 'One or more domains failed to validate'
                    logging.error(reason)
            data['Arn'] = arn
            # delay as long as possible to give the cert a chance to propogate
            while context.get_remaining_time_in_millis() / 1000.00 > 10.0:
                time.sleep(5)
        elif event['RequestType'] == 'Update':
            reason = 'Exception: Stack updates are not supported'
            logging.error(reason)
            status = cfnresponse.FAILED
            physical_resource_id = event['PhysicalResourceId']
        elif event['RequestType'] == 'Delete':
            physical_resource_id=event['PhysicalResourceId']
            if not re.match(r'arn:[\w+=/,.@-]+:[\w+=/,.@-]+:[\w+=/,.@-]*:[0-9]+:[\w+=,.@-]+(/[\w+=,.@-]+)*', physical_resource_id):
                logging.info("PhysicalId is not an acm arn, assuming creation never happened and skipping delete")
            else:
                rs={}
                for d in acm_client.describe_certificate(CertificateArn=physical_resource_id)['Certificate']['DomainValidationOptions']:
                    rs[d['ResourceRecord']['Name']] = d['ResourceRecord']['Value']
                rs = [{'Action': 'DELETE', 'ResourceRecordSet': {'Name': r, 'Type': 'CNAME', 'TTL': 600,'ResourceRecords': [{'Value': rs[r]}]}} for r in rs.keys()]
                try:
                    r53_client.change_resource_record_sets(HostedZoneId=event['ResourceProperties']['HostedZoneId'], ChangeBatch={'Changes': rs})
                except r53_client.exceptions.InvalidChangeBatch as e:
                    pass
                time.sleep(30)
                try:
                    acm_client.delete_certificate(CertificateArn=physical_resource_id)
                except acm_client.exceptions.ResourceInUseException as e:
                    time.sleep(60)
                    acm_client.delete_certificate(CertificateArn=physical_resource_id)

    except Exception as e:
        logging.error('Exception: %s' % e, exc_info=True)
        reason = str(e)
        status = cfnresponse.FAILED
    finally:
        if event['RequestType'] == 'Delete':
            try:
                wait_message = 'waiting for events for request_id %s to propagate to cloudwatch...' % context.aws_request_id
                while not logs_client.filter_log_events(
                        logGroupName=context.log_group_name,
                        logStreamNames=[context.log_stream_name],
                        filterPattern='"%s"' % wait_message
                )['events']:
                    print(wait_message)
                    time.sleep(5)
            except Exception as e:
                logging.error('Exception: %s' % e, exc_info=True)
                time.sleep(120)
        cfnresponse.send(event, context, status, data, physical_resource_id, reason)
