""" Add a realm """

import argparse
import copy
import json
import re
import shutil
import sys
import time
from pathlib import Path
import requests
from lib.python import utils, defaults
from lib.python.realm_common import apply_ldifs


KUBECTL = defaults.KUBECTL
ERR_STR = "ERROR!!"
WARN_STR = "WARNING!!"


def to_title_case(name: str) -> str:
    """ Matches existing style: user->User, role->Role, etc. """
    return name[:1].upper() + name[1:]


def make_schema_id(realm: str, object_name: str) -> str:
    """ Consistent schema id for cloned managed objects """
    return f"urn:jsonschema:org:forgerock:openidm:managed:api:{realm}_{to_title_case(object_name)}"


def check_replicas(namespace: str) -> bool:
    """ Check that the replica count for AM, IDM, and the DSes is 1.
        Return True if it does, otherwise return False """

    resources = {
        'deployment': ['am', 'idm'],
        'statefulset': ['ds-cts', 'ds-idrepo'],
    }
    check_ok = True
    for r, apps in resources.items():
        for app in apps:
            if utils.is_k8s_resource(r, app, namespace):
                _, app_json, _ = utils.run(KUBECTL, f"get {r} {app} -o json -n {namespace}",
                                         cstdout=True, cstderr=True, ignoreFail=True)
                app_dct = json.loads(app_json)
                if app_dct['spec']['replicas'] != 1:
                    print(f'{ERR_STR} {app} replicas are not 1. Run this against a single instance deployment.')
                    check_ok = False
            else:
                print(f"Didn't find a {app} {r}. This command only works on a Ping AIS Platform.")
                check_ok = False
    return check_ok


def pre_check(params, settings):
    """ Check to make sure we are ready to go """
    print('Running pre-creation checks')
    is_problem = False
    print('Checking Helm env')
    settings['helm_env_path'] = settings['helm_path'] / params.env_name
    if params.debug:
        print(f"helm_env_path={settings['helm_env_path']}")
    helm_env_path = settings['helm_env_path']
    if utils.check_path(helm_env_path, 'Helm path', 'dir', True):
        print(f'Success! {helm_env_path} is a dir')
    else:
        print(f'{helm_env_path} is not a dir. Check --env-name and try again.')
        is_problem = True
    print('Checking replicas')
    if check_replicas(settings['namespace']):
        print('Success! Replica count is 1 for am, idm, ds-cts, and ds-idrepo.')
    else:
        print('Failure! Not on a single instance deployment.')
        is_problem = True

    if is_problem:
        utils.exit_msg('Resolve issues listed above, and rerun the script.')
    else:
        print('No issues found. Continuing.')


def create_ldifs(params, settings):
    """ Create the ldif file for the new realm """
    files = [
        'docker/ds/ldif-ext/am-config/realm.ldif.tmpl',
        'docker/ds/ldif-ext/identities/realm-orgs.ldif.tmpl']

    for file in files:
        source = settings['root_path'] / file
        file_n = f"{params.realm}.ldif"
        if 'realm-orgs' in file:
            file_n = f"{params.realm}-orgs.ldif"
        target = source.parent / file_n
        if params.dryrun:
            print(f"DRYRUN: Would create {target}")
            continue
        if target.exists():
            print(f"{target} already exists, skipping.")
            continue
        content = source.read_text(encoding="utf-8")
        updated = content.replace("REALM_NAME", params.realm)
        target.write_text(updated, encoding="utf-8")
        print(f"Created new realm ldif: {target}")


def create_amster_profile(params, settings):
    """ Create the amster profile for the new realm, to apply needed dynamic config
        Needed configs are:
            OAuth clients
    """
    profile_root = settings['root_path'] / 'docker/amster/config-profiles'
    default_profile = profile_root / 'default'
    target_profile = profile_root / f'realm-{params.realm}'

    if params.debug:
        print(f"profile_root={profile_root}")
        print(f"default_profile={default_profile}")
        print(f"target_profile={target_profile}")

    if params.dryrun:
        print(f"DRYRUN: Would create amster profile {target_profile}")
        return

    realm_root = target_profile / f"config/realms/root-{params.realm}"
    (realm_root / "Applications").mkdir(parents=True, exist_ok=True)
    (realm_root / "IdentityGatewayAgents").mkdir(parents=True, exist_ok=True)
    (realm_root / "OAuth2Clients").mkdir(parents=True, exist_ok=True)

    shutil.copy2(
        default_profile / "config/realms/root/Applications/oauth2Scopes.json",
        realm_root / "Applications/oauth2Scopes.json",
    )
    shutil.copy2(
        default_profile / "config/realms/root/IdentityGatewayAgents/ig-agent.json",
        realm_root / "IdentityGatewayAgents/ig-agent.json",
    )
    shutil.copy2(
        default_profile / "config/realms/root/OAuth2Clients/idm-provisioning.json",
        realm_root / "OAuth2Clients/idm-provisioning.json",
    )
    shutil.copy2(
        default_profile / "config/realms/root/OAuth2Clients/idm-admin-ui.json",
        realm_root / "OAuth2Clients/idm-admin-ui.json",
    )
    shutil.copy2(
        default_profile / "config/realms/root/OAuth2Clients/end-user-ui.json",
        realm_root / "OAuth2Clients/end-user-ui.json",
    )

    for json_file in realm_root.rglob("*.json"):
        data = json.loads(json_file.read_text(encoding="utf-8"))
        metadata = data.get("metadata")
        if isinstance(metadata, dict) and metadata.get("realm") == "/":
            metadata["realm"] = f"/{params.realm}"
            json_file.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")

    print(f'Updated metadata.realm to "/{params.realm}" in JSON files under {realm_root}')


def rewrite_resource_collections(obj: object, realm: str) -> None:
    """Recursively rewrite managed/<src> resourceCollection values to managed/<realm>_<src>."""
    if isinstance(obj, dict):
        if "meta" in obj and isinstance(obj["meta"], dict) and obj.get("name") == f"{realm}_user":
            if "resourceCollection" in obj["meta"]:
                obj["meta"]["resourceCollection"] = f"managed/{realm}_usermeta"
        elif "resourceCollection" in obj and isinstance(obj["resourceCollection"], list):
            for col in obj["resourceCollection"]:
                if 'path' in col:
                    col["path"] = re.sub(r"managed/(\w+)", rf"managed/{realm}_\g<1>", col["path"])
        for val in obj.values():
            rewrite_resource_collections(val, realm)
    elif isinstance(obj, list):
        for item in obj:
            rewrite_resource_collections(item, realm)


def update_idm_managed_json(params, settings):
    """ Update managed.json in IDM config-profile """
    if params.dryrun:
        print(f"Dryrun given, not updating managed.json for {params.realm} realm.")
        return
    source_names = [
        "user",
        "usermeta",
        "application",
        "role",
        "organization",
        "group",
        "aiagent",
        "aiagentprivilege"]
    idm_profiles = settings['root_path'] / "docker/idm/config-profiles"
    target_profile = idm_profiles / params.config_profile
    managed_path = target_profile / "conf/managed.json"
    if not managed_path.is_file():
        print(f"{ERR_STR} Can't find {managed_path}. Exiting.")
        sys.exit(1)
    data = json.loads(managed_path.read_text(encoding="utf-8"))

    if "objects" not in data or not isinstance(data["objects"], list):
        raise ValueError(f"Expected 'objects' list in {managed_path}")

    objects = data["objects"]

    # Index existing objects by name for easy lookup/update
    by_name = {}
    for obj in objects:
        if isinstance(obj, dict) and "name" in obj:
            by_name[obj["name"]] = obj

    usermeta_name = f"{params.realm}_usermeta"
    usermeta_obj = {
        "name": f"{usermeta_name}",
        "schema": {
            "description": None,
            "icon": "fa-database",
            "mat-icon": None,
            "properties": {},
            "title": f"{params.realm} realm - metadata for user"
        }
    }
    if not by_name.get(usermeta_name):
        by_name[usermeta_name] = usermeta_obj
        objects.append(usermeta_obj)

    for src_name in source_names:
        src_obj = by_name.get(src_name)
        if not src_obj:
            print(f"Skipping missing source object: {src_name}")
            continue

        target_name = f"{params.realm}_{src_name}"

        # Clone from source
        cloned = copy.deepcopy(src_obj)
        cloned["name"] = target_name

        schema = cloned.get("schema")
        if not isinstance(schema, dict):
            schema = {}
            cloned["schema"] = schema

        schema["id"] = make_schema_id(params.realm, src_name)
        schema["title"] = f"{params.realm.capitalize()} realm {to_title_case(src_name)}"

        rewrite_resource_collections(cloned, params.realm)
        # Upsert so script is idempotent (safe to re-run)
        existing = by_name.get(target_name)
        if existing is not None:
            existing.clear()
            existing.update(cloned)
            print(f"Updated existing object: {target_name}")
        else:
            objects.append(cloned)
            by_name[target_name] = cloned
            print(f"Added object: {target_name}")

    managed_path.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")
    print(f"Wrote {managed_path}")


def rewrite_resource_paths(obj: object, realm: str, source_names: list) -> None:
    """Recursively rewrite managed/<src> resourcePath values to managed/<realm>_<src>."""
    if isinstance(obj, dict):
        if "resourcePath" in obj and isinstance(obj["resourcePath"], str):
            for src in source_names:
                prefix = "managed"
                if src == "usermeta":
                    prefix = "internal"
                if obj["resourcePath"] == f"{prefix}/{src}":
                    obj["resourcePath"] = f"managed/{realm}_{src}"
                    break
        for val in obj.values():
            rewrite_resource_paths(val, realm, source_names)
    elif isinstance(obj, list):
        for item in obj:
            rewrite_resource_paths(item, realm, source_names)


def update_idm_repo_ds_json(params, settings):
    """ Update repo.ds.json in IDM config-profile """
    if params.dryrun:
        print(f"Dryrun given, not updating repo.ds.json for {params.realm} realm.")
        return
    # Source managed object names to duplicate
    source_names = [
        "user",
        "usermeta",
        "application",
        "role",
        "organization",
        "group",
        "assignment",
        "aiagent",
        "aiagentprivilege"]
    explicit_sources = [
        "aiagent",
        "aiagentprivilege"]

    # Map each source object to its new dnTemplate under the realm's identity store
    dn_template_map = {
            "user": f"ou=people,o={params.realm},o=root,ou=identities",
            "usermeta": f"ou=usermeta,o={params.realm},o=root,ou=identities",
            "role": f"ou=role,o={params.realm},o=root,ou=identities",
            "assignment": f"ou=assignment,o={params.realm},o=root,ou=identities",
            "organization": f"o={params.realm},o=root,ou=identities",
            "group": f"ou=groups,o={params.realm},o=root,ou=identities",
            "application": f"ou=application,o={params.realm},o=root,ou=identities",
            "aiagent": f"ou=aiagents,o={params.realm},o=root,ou=identities",
            "aiagentprivilege": f"ou=aiagentprivilege,o={params.realm},o=root,ou=identities",
    }

    profile_path = settings['root_path'] / f"docker/idm/config-profiles/{params.config_profile}"
    repo_path = profile_path / "conf/repo.ds.json"
    if not repo_path.is_file():
        print(f"{ERR_STR} Can't find {repo_path}. Exiting.")
        sys.exit(1)
    data = json.loads(repo_path.read_text(encoding="utf-8"))

    explicit = data.get("resourceMapping", {}).get("explicitMapping")
    generic = data.get("resourceMapping", {}).get("genericMapping")
    if not isinstance(explicit, dict):
        raise ValueError(f"resourceMapping.explicitMapping not found in {repo_path}")
    if not isinstance(generic, dict):
        raise ValueError(f"resourceMapping.genericMapping not found in {repo_path}")
    for src_name in source_names:
        src_key = f"managed/{src_name}"
        if src_name == 'usermeta':
            src_key = f"internal/{src_name}"
        src_mapping = generic.get(src_key)
        if src_name in explicit_sources:
            src_mapping = explicit.get(src_key)
        if not src_mapping:
            print(f"Skipping missing source mapping: {src_key}")
            continue

        target_key = f"managed/{params.realm}_{src_name}"

        # Clone and rewrite
        cloned = copy.deepcopy(src_mapping)

        # Update dnTemplate
        if src_name in dn_template_map:
            cloned["dnTemplate"] = dn_template_map[src_name]

        # Rewrite all internal resourcePath references
        rewrite_resource_paths(cloned, params.realm, source_names)

        # Upsert (idempotent)
        if target_key in explicit:
            explicit[target_key] = cloned
            print(f"Updated existing mapping: {target_key}")
        elif target_key in generic:
            generic[target_key] = cloned
            print(f"Updated existing mapping: {target_key}")
        else:
            if src_name in explicit_sources:
                explicit[target_key] = cloned
                print(f"Added mapping: {target_key}")
            else:
                generic[target_key] = cloned
                print(f"Added mapping: {target_key}")

    repo_path.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")
    print(f"Wrote {repo_path}")


def _get_am_token(fqdn, admin_pw, timeout='300s', verify=True):
    api_url = f"https://{fqdn}/am/json/realms/root/authenticate"
    headers = {
        "X-OpenAM-Username": "amadmin",
        "X-OpenAM-Password": admin_pw,
        "Content-Type": "application/json"
    }
    try:
        utils.run(KUBECTL, f"rollout status deployment am --timeout={timeout}")
    except Exception as exc:
        raise RuntimeError("AM is not ready. Check your deployment, and try again.") from exc
    try:
        response = requests.post(api_url, headers=headers,
                                 timeout=10, verify=verify)
        response.raise_for_status()
        data = response.json()
        return data["tokenId"]
    except Exception as exc:
        raise RuntimeError("AM returned bad data") from exc


def create_realm(params, settings):
    """ Create the realm using the API """
    if params.dryrun:
        print(f"Dryrun given, not creating {params.realm} realm.")
        return
    verify = not getattr(params, 'insecure', False)
    token = _get_am_token(settings['fqdn'], settings['admin_pw'], verify=verify)
    realm_url = f"https://{settings['fqdn']}/am/json/global-config/realms"
    headers = {
        "iPlanetDirectoryPro": token,
        "Accept-API-Version": "resource=1.0",
    }

    for attempt in range(1, 21):
        try:
            response = requests.get(f"{realm_url}?_queryFilter=true", headers=headers,
                                    timeout=10, verify=verify)
            existing = {realm["name"] for realm in response.json()["result"]}
            break
        except requests.exceptions.RequestException as e:
            if attempt == 20:
                raise e
            print(f"  AM realms endpoint not ready yet (attempt {attempt}/20), retrying in 15s...")
            time.sleep(15)
            token = _get_am_token(settings['fqdn'], settings['admin_pw'], verify=verify)

    if params.realm in existing:
        print(f"Realm {params.realm!r} already exists, skipping")
    else:
        print(f"Creating realm {params.realm!r}...")
        headers["Content-Type"] = "application/json"
        aliases = []
        if getattr(params, "aliases", None):
            aliases = params.aliases.split(',')
        realm_data = {
            "name": params.realm,
            "parentPath": '/',
            "active": True,
            "aliases": aliases
        }
        try:
            response = requests.post(f"{realm_url}/?_action=create",
                                    json=realm_data,
                                    headers=headers,
                                    timeout=10,
                                    verify=verify).raise_for_status()
            print("created.")
        except requests.exceptions.RequestException as e:
            raise e


def update_am_fbc(params, settings):
    """ Update the AM FBC
        * change ou=identities to o=REALM,o=root,ou=identities
    """
    if params.dryrun:
        print(f"Dryrun given. Not attempting to update am config-profile ({params.realm})")
        return
    profile_root = settings['root_path'] / "docker/am/config-profiles"
    profile_path = profile_root / params.config_profile
    if params.config_profile.startswith("/"):
        profile_path = Path(params.config_profile)
    opendj_f = profile_path / f"config/services/realm/root-{params.realm}/sunidentityrepositoryservice/1.0/organizationconfig/default/opendj.json"
    opendj_json = {}
    if opendj_f.is_file():
        with open(opendj_f, encoding='utf-8') as f:
            opendj_json = json.load(f)
        opendj_json['data']['ldapsettings']['sun-idrepo-ldapv3-config-organization_name'] = f'o={params.realm},o=root,ou=identities'
        opendj_json['data']['persistentsearch']['sun-idrepo-ldapv3-config-psearchbase'] = f'o={params.realm},o=root,ou=identities'
        with open(opendj_f, "w", encoding='utf-8') as json_file:
            json_file.write(json.dumps(opendj_json, indent=4) + "\n")
        print("Identity Store updated in FBC")
    else:
        print(f"{ERR_STR} {opendj_f} doesn't exist.", file=sys.stderr)
        sys.exit(1)


def export_fbc(app: str, params, settings):
    """ Create the realm in the platform API """
    if app not in ['am', 'idm']:
        print(f"{ERR_STR} App {app} not am or idm, exiting", file=sys.stderr)
        sys.exit(1)
    export_cmd = f"{settings['root_path']}/bin/forgeops"
    cmd_opts = "config export"
    if app == 'am':
        cmd_opts += f" -e {params.env_name}"
    cmd_opts += f" {app} {params.config_profile}"

    utils.run(export_cmd, cmd_opts, debug=params.debug, dryrun=params.dryrun)


def build_image(app: str, params, settings):
    """ Build an image """
    if not params.no_build:
        print(f"Building {app} {params.build_type} image")
        cmd = f"{settings['root_path']}/bin/forgeops"
        cmd_opts = "config build"
        if params.build_type == 'app':
            cmd_opts = 'build'
        cmd_opts += f" -e {params.env_name} -p {params.config_profile}"
        cmd_opts += f" -H {settings['helm_path']} -k {settings['kustomize_path']}"
        if getattr(params, 'tag', None):
            cmd_opts += f" -t {params.tag}"
        if getattr(params, 'skip_image_append', None):
            cmd_opts += f" --skip-image-append --push-to {getattr(params, f'{app}_push_to', 'none')}"
        else:
            if getattr(params, 'push_to', None):
                cmd_opts += f" --push-to {params.push_to}"
            else:
                cmd_opts += " --push-to none"
        cmd_opts += f" {app}"
        utils.run(cmd, cmd_opts, debug=params.debug, dryrun=params.dryrun)
    else:
        print(f"Build of {app} skipped.")
        print(f"Be sure to build an {app} image so you can deploy your new realm.")


class ArgFormatter(argparse.ArgumentDefaultsHelpFormatter, argparse.RawDescriptionHelpFormatter):
    """ Setup an Argument Formatter """


def setup_args(subparsers, common_args):
    """ Setup arguments for forgeops realm create """

    prog = "forgeops realm create"
    desc = "Create a realm"
    epilog = f"""

  This command will create a new realm against a single instance environment.
  It prepares the file based config, dynamic config, ldif file, and container
  images for a multi instance deployment. Use `forgeops realm apply` to apply
  changes to the multi instance deployment.

  Notes:
    * New image deployment is Helm only.
    * Kustomize must deploy new images manually.
    * The name of your config profile must match between AM and IDM.
    * Use --am-push-to and --idm-push-to when using --skip-image-append.
      * If you don't, the images won't be pushed.

  Examples:
    Create accounting realm:
    ./{prog} -e test-env-single -p test accounting

    Create acct-recv subrealm:
    ./{prog} -e test-env-single -p test -P accounting acct-recv

    Create admin realm with aliases:
    ./{prog} -e test-env-single -p test -a alias1,alias2 admin

"""
    parser = subparsers.add_parser('create',
                                   help=desc,
                                   prog=prog,
                                   epilog=epilog,
                                   parents=[common_args['debug'],
                                            common_args['dryrun'],
                                            common_args['env_name_req'],
                                            common_args['config_profile_req'], common_args['helm_path'],
                                            common_args['kustomize_path'],
                                            common_args['namespace'],
                                            common_args['push_to'],
                                            common_args['skip_image_append'],
                                            common_args['tag_def'],
                                            common_args['chart_name'],
                                            common_args['chart_version'],
                                            common_args['chart_repo']],
                                   formatter_class=ArgFormatter)
    parser.add_argument('--build-type', choices=['app', 'custom'],
                        default='custom',
                        help='Build method to use when building images')
    parser.add_argument('--no-build', action='store_true',
                        help="Don't build AM, IDM, and DS images")
    parser.add_argument('--aliases', '-a',
                        help='Alias FQDNs [comma separated]')
    parser.add_argument('--am-push-to',
                        default='none',
                        help='Image registry to use with AM. Used with --skip-image-append.')
    parser.add_argument('--idm-push-to',
                        default='none',
                        help='Image registry to use with IDM. Used with --skip-image-append.')
    parser.add_argument('--insecure',
                        action='store_true',
                        help='Ignore SSL certificate errors')
    parser.add_argument('realm', help='Name of realm to create')
    return parser


def run(args, config):
    """ Create the realm """

    config['namespace'] = utils.get_namespace(getattr(args, 'namespace', None))
    config['fqdn'] = utils.get_fqdn(config['namespace'])
    config['admin_pw'] = utils.get_secret_value(config['namespace'],
                                                "am-env-secrets",
                                                "AM_PASSWORDS_AMADMIN_CLEAR")
    if args.insecure:
        requests.packages.urllib3.disable_warnings(
            category = requests.packages.urllib3.exceptions.InsecureRequestWarning)

    if not getattr(args, 'push_to', None) and (args.am_push_to == 'none' and args.idm_push_to == 'none'):
        if not utils.is_local_k8s_context():
            print("No push-to flags given, and Kubernetes context is not local. Exiting.")
            sys.exit(1)

    pre_check(args, config)
    create_ldifs(args, config)
    apply_ldifs(args.realm, config['namespace'], config['root_path'],
                debug=args.debug, dryrun=args.dryrun)
    create_amster_profile(args, config)
    export_fbc('idm', args, config)
    update_idm_managed_json(args, config)
    update_idm_repo_ds_json(args, config)
    create_realm(args, config)
    export_fbc('am', args, config)
    update_am_fbc(args, config)
    build_image('am', args, config)
    build_image('idm', args, config)

    profile_root = config['root_path'] / 'docker/amster/config-profiles'
    amster_profile = profile_root / f'realm-{args.realm}'
    utils.apply_amster_profile(amster_profile, args.env_name, config['namespace'],
                               config['root_path'], getattr(args, 'helm_path', None),
                               getattr(args, 'kustomize_path', None),
                               debug=args.debug, dryrun=args.dryrun)

    if utils.check_helm_installed():
        if utils.check_chart(config['namespace'], args.chart_name):
            values_f = config['helm_path'] / args.env_name / 'values.yaml'
            utils.run_helm_cmd(values_f,
                               config['namespace'],
                               dryrun=args.dryrun,
                               debug=args.debug,
                               chart_name=getattr(args, 'chart_name', None),
                               chart_repo=getattr(args, 'chart_repo', None),
                               chart_version=getattr(args, 'chart_version', None))
        else:
            print(f"Could not find the {args.chart_name} Helm chart in {config['namespace']}. Not running helm.")
    else:
        print("Could not find the helm command. Not running helm.")
