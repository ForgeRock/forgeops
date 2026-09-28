""" Common realm functions """

import json
import sys
from lib.python import utils, defaults


KUBECTL = defaults.KUBECTL
ERR_STR = "ERROR!!"
WARN_STR = "WARNING!!"


def apply_ldifs(realm: str, namespace: str, root_path: str, debug:bool=False, dryrun:bool=False):
    """ Apply the ldifs to the DS idrepo pods """
    pods_all = utils.get_pod_names("app.kubernetes.io/component=ds-idrepo", namespace)
    if not pods_all:
        print(f"Unable to find a ds-idrepo pod. Please ensure you are pointed at a ForgeOps deployment.")
        sys.exit(1)
    pod = pods_all[0] # Grab the first pod since applying the ldif to one, replicates
    conn_str, pass_file = utils.setup_ds_cmds([pod], namespace, debug=debug, dryrun=dryrun)
    print(f"Checking {pod} to see if {realm} realm already exists.")
    if utils.check_realm_in_ds(realm, pod, namespace, conn_str, debug=debug, dryrun=dryrun):
        print(f"Realm {realm} already exists on {pod}. Not applying ldif.")
    else:
        am_config_ldif = root_path / f'docker/ds/ldif-ext/am-config/{realm}.ldif'
        orgs_ldif = root_path / f'docker/ds/ldif-ext/identities/{realm}-orgs.ldif'
        if not am_config_ldif.is_file():
            print(f"ERROR!! Missing {am_config_ldif}. Exiting.")
            sys.exit(1)
        if not orgs_ldif.is_file():
            print(f"ERROR!! Missing {orgs_ldif}. Exiting.")
            sys.exit(1)
        files = [{
            'pod': pod,
            'src': am_config_ldif,
            'dst': f'/tmp/{realm}.ldif',
            'no_preserve': True,
        },
        {
            'pod': pod,
            'src': orgs_ldif,
            'dst': f'/tmp/{realm}-orgs.ldif',
            'no_preserve': True,
        }]
        utils.ldif_apply(files, namespace, conn_str, debug=debug, dryrun=dryrun)
    utils.cleanup_ds_cmds([pod], namespace, pass_file, debug=debug, dryrun=dryrun)
