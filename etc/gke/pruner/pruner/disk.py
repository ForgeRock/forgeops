import sys
import os
from datetime import datetime, timedelta
import logging

import googleapiclient.discovery

log = logging.getLogger('disk-pruner')
log.info('initializing disk pruner')

MAX_DISK_AGE = timedelta(int(os.environ.get('MAX_DISK_AGE', 30)))
DRY_RUN = os.environ.get('DRY_RUN', False)
PROJECT = os.environ.get('GOOGLE_CLOUD_PROJECT', 'engineering-devops')

compute = googleapiclient.discovery.build('compute', 'v1')

def disk_delete(zone, name):
    if DRY_RUN:
        log.info(f'would have deleted zone={zone} disk={name}')
        return True
    response = compute.disks().delete(
        zone=zone,
        project=PROJECT,
        disk=name).execute()
    if 'error' in response:
        if 'errors' in response['error']:
            log.error(f'error during deletion zone={zone} disk={name}')
            return False
    return True

def prune_disks():
    zone_results = compute.zones().list(project=PROJECT).execute()
    if not 'items' in zone_results:
        print('no zones found...')
        sys.exit(1)
    zones = [i['name'] for i in zone_results['items']]
    delete_errors = 0
    delete_size_total = 0
    for zone in zones:
        disk_results = compute.disks().list(zone=zone,
                                            project=PROJECT).execute()
        if not 'items' in disk_results:
            continue
        for item in disk_results['items']:
            # users is a link to the user (e.g. gke instance) using disk
            # we skip these disks
            if 'users' in item:
                continue
            attached_time_str = item['lastAttachTimestamp']
            attached_time = datetime.fromisoformat(attached_time_str)
            current_time = datetime.now()
            # skip if newer than max age
            if current_time - attached_time.replace(tzinfo=None) < MAX_DISK_AGE:
                continue
            deleted = disk_delete(zone, item['name'])
            if deleted:
                delete_size_total += int(item['sizeGb'])
            else:
                delete_errors += 1
    if delete_errors != 0:
        log.error(f'{delete_errors} errors occured while pruning')
        return False
    log.info(f'pruned {delete_size_total} Gb')
    return True
