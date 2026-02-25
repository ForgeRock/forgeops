"""Upgrade a ForgeOps environment to the latest updates"""

from copy import copy
import datetime
import os
from pathlib import Path
import shutil
import site
import sys
import yaml

file_name = Path(__file__)
current_file_path = file_name.parent.resolve()
root_path = [parent_path for parent_path in current_file_path.parents if (parent_path / 'README.md').exists()][0]
dependencies_dir = os.path.join(root_path, 'lib', 'dependencies')
# Insert lib folders to python path
sys.path.insert(0, str(root_path))
sys.path.insert(1, str(dependencies_dir) + site.USER_SITE.replace(site.USER_BASE, ''))

from lib.python.defaults import SNAPSHOT_ROLE_NAME
from lib.python.common import write_yaml_file, log
import lib.python.utils as utils


def copy_default_overlay_from_root(overlay_path, default_overlay):
    """ Update the default overlay by copying from root """
    root_default = Path(root_path) / 'kustomize' / 'overlay' / 'default'
    if root_default.resolve() != default_overlay.resolve():
        if root_default.is_dir():
            log(f"Removing current default dir {default_overlay}", overlay_path)
            shutil.rmtree(default_overlay)
        log("Copying default overlay from ForgeOps root", overlay_path)
        shutil.copytree(root_default, default_overlay)



def update_secrets_2025_2_0(overlay_path, source_path):
    """ Update secrets child overlay (2025.2.0)"""
    log('Checking secrets child overlay for 2025.2.0 updates', overlay_path)
    secrets_path = overlay_path / 'secrets'
    secrets_path_bak = overlay_path / 'secrets.bak'
    sa_path = secrets_path / 'secret-agent'
    sg_path = secrets_path / 'secret-generator'
    source_secrets_path = source_path / 'secrets'
    src_sa_path = source_secrets_path / 'secret-agent'
    src_sg_path = source_secrets_path / 'secret-generator'
    if secrets_path.is_dir():
        if sa_path.is_dir() and sg_path.is_dir():
            log(f"{secrets_path} already updated", overlay_path)
        else:
            log(f"Updating {secrets_path}", overlay_path)
            log(f"Checking {source_secrets_path}", overlay_path)
            if src_sa_path.is_dir() and src_sg_path.is_dir():
                log(f"{source_secrets_path} is up to date. Continuing.", overlay_path)
            else:
                utils.exit_msg(f"{source_secrets_path} isn't up to date. Run this script on that overlay with default as the source.")
            log("Backing up current secrets child overlay...", overlay_path, end="")
            shutil.move(secrets_path, secrets_path_bak)
            log('done', overlay_path)
            log(f"Copying {source_secrets_path} to {secrets_path}...", overlay_path, end="")
            shutil.copytree(source_secrets_path, secrets_path)
            log('done', overlay_path)
            log(f"The {secrets_path} child overlay has been updated", overlay_path)
            log('Please note that secret-agent is enabled by default.', overlay_path)

    ldif_importer_path = overlay_path / 'ldif-importer'
    ds_set_passwords_path = overlay_path / 'ds-set-passwords'
    def_ds_set_passwords_path = source_path / 'ds-set-passwords'
    if ldif_importer_path.exists():
        log("Removing old ldif-importer child overlay from default.", overlay_path)
        shutil.rmtree(ldif_importer_path)
    if not ds_set_passwords_path.is_dir():
        log("Copying ds-set-passwords child overlay from default.", overlay_path)
        shutil.copytree(def_ds_set_passwords_path, ds_set_passwords_path)
    kust_path = overlay_path / 'kustomization.yaml'
    ldif_str = './ldif-importer'
    dsp_str = './ds-set-passwords'
    if kust_path.is_file():
        kust = {}
        with open(kust_path, encoding='utf-8') as f:
            kust = yaml.safe_load(f)
        if ldif_str in kust['resources']:
            log("Replacing ldif-importer with ds-set-passwords.", overlay_path)
            kust['resources'] = utils.replace_or_append_str(kust['resources'],
                                                            ldif_str,
                                                            dsp_str)
        if dsp_str not in kust['resources']:
            log("Adding ds-set-passwords into overlay resources.", overlay_path)
            kust['resources'].append(dsp_str)

        write_yaml_file(kust, kust_path)


def update_apps_2025_2_0(overlay_path, default_overlay):
    """ Update am child overlay (2025.2.0)"""
    log('Checking idm, am, and amster child overlays for 2025.2.0 updates', overlay_path)
    base_path = '../../../base'
    paths = [
        {
            'path': overlay_path / 'am',
            'old_resource': f'{base_path}/am',
            'new_resource': f'{base_path}/am/secret-agent'
        },
        {
            'path': overlay_path / 'amster',
            'old_resource': f'{base_path}/amster',
            'new_resource': f'{base_path}/amster/secret-agent'
        },
        {
            'path': overlay_path / 'idm',
            'old_resource': f'{base_path}/idm',
            'new_resource': f'{base_path}/idm/secret-agent'
        }
    ]
    do_update = False
    def_keystore_path = default_overlay / 'keystore-create'
    keystore_path = overlay_path / 'keystore-create'
    if keystore_path.is_dir():
        log("Found keystore-create child overlay. Continuing.", overlay_path)
    else:
        log("Didn't find keystore-create child overlay, copying from default.", overlay_path)
        shutil.copytree(def_keystore_path, keystore_path)
        do_update = True
    for p in paths:
        if p['path'].is_dir():
            kust_path = p['path'] / 'kustomization.yaml'
            if kust_path.is_file():
                with open(kust_path, encoding='utf-8') as f:
                    kust = yaml.safe_load(f)
                if p['old_resource'] in kust['resources']:
                    log(f"Updating {p['path']} ...", overlay_path, end="")
                    kust['resources'] = list(set(utils.replace_or_append_str(kust['resources'], p['old_resource'], p['new_resource'])))
                    write_yaml_file(kust, kust_path)
                    log('done', overlay_path)
                    do_update = True
                else:
                    log(f"{p['path']} already updated", overlay_path)
            else:
                utils.exit_msg(f"{kust_path} is not a file. Please specify a valid environment.")
        else:
            utils.exit_msg(f"{p['path']} is not a directory. Please specify a valid environment.")

    if do_update:
        log('Please note, the updated child overlays are configured for secret-agent.', overlay_path)


def update_secrets_2025_2_1(helm_env_path):
    """ Update Helm values.yaml (2025.2.1)"""
    values_file = helm_env_path / 'values.yaml'
    if values_file.is_file():
        values = {}
        with open(values_file, encoding='utf-8') as f:
            values = yaml.safe_load(f)
        if utils.key_exists(values, 'platform.secret_generator_enable'):
            values['platform']['secrets_enabled'] = values['platform']['secret_generator_enable']
            del values['platform']['secret_generator_enable']
            if utils.key_exists(values['platform'], 'secrets.amster.annotations.type'):
                type_val = values['platform']['secrets']['amster']['annotations']['type']
                values['platform']['secrets']['amster']['annotations']['secret-generator.v1.mittwald.de/type'] = type_val
                del values['platform']['secrets']['amster']['annotations']['type']
            write_yaml_file(values, values_file)
    else:
        print(f"{values_file} doesn't exist, not updating. Check your environment and try again.")


def update_secrets_2026_1_0(overlay_path, default_overlay):
    """ Update image-defaulter (2026.1.0)"""
    names = None
    if default_overlay.is_dir():
        kust_file = default_overlay / 'image-defaulter' / 'kustomization.yaml'
        kust = {}
        with open(kust_file, encoding='utf-8') as f:
            kust = yaml.safe_load(f)
        names = [d.get('name') for d in kust['images'] if 'name' in d]
        if 'am-custom' not in names:
            log("Default overlay out of date, copying from ForgeOps root.", overlay_path)
            copy_default_overlay_from_root(overlay_path, default_overlay)
    if overlay_path.is_dir():
        log(f"Checking overlay {overlay_path}", overlay_path)
        image_info = {
            'name': None,
            'newName': 'busybox',
            'newTag': 'musl'
        }
        kust_file = overlay_path / 'image-defaulter' / 'kustomization.yaml'
        kust = {}
        do_update_kust = False
        with open(kust_file, encoding='utf-8') as f:
            kust = yaml.safe_load(f)
        names = [d.get('name') for d in kust['images'] if 'name' in d]
        for c_app in ['am-custom', 'idm-custom']:
            if c_app not in names:
                log(f"Adding {c_app}", overlay_path)
                do_update_kust = True
                data = copy(image_info)
                data['name'] = c_app
                kust['images'].append(data)
        if do_update_kust:
            write_yaml_file(kust, kust_file)

        do_update_deploy = False
        for app in ['am', 'idm']:
            app_path = overlay_path / app
            if not app_path.is_dir():
                continue
            deploy_file = app_path / 'deployment.yaml'
            deployment = {}
            with open(deploy_file, encoding='utf-8') as f:
                deployment = yaml.safe_load(f)
            if utils.key_exists(deployment, 'spec.template.spec.initContainers'):
                init_containers = deployment['spec']['template']['spec']['initContainers']
                found_custom = False
                for c in init_containers:
                    if c['name'] == 'fbc-init':
                        log(f"Changing fbc-init to filesystem-init in {app} deployment", overlay_path)
                        c['name'] = 'filesystem-init'
                        do_update_deploy = True
                    if c['name'] == 'custom-vol-init':
                        found_custom = True
                if not found_custom:
                    log(f"Adding custom-vol-init to {app} deployment", overlay_path)
                    do_update_deploy = True
                    data = {
                        'name': 'custom-vol-init',
                        'resources': {}
                    }
                    init_containers.append(data)
                if do_update_deploy:
                    write_yaml_file(deployment, deploy_file)
        if not (do_update_kust or do_update_deploy):
            log(f"{overlay_path} already updated", overlay_path)
    else:
        print(f"{overlay_path} doesn't exist, not updating. Check your environment and try again.")


def run(args, config):
    """ Run upgrades """
    def_overlay_path = config['overlay_root'] / 'default'
    config['overlay_path'] = config['overlay_root'] / args.env_name
    config['source_path'] = config['overlay_root'] / config['source_overlay']
    config['helm_env_path'] = config['helm_path'] / args.env_name

    timestamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d-%H:%M:%S%z")
    header=f"""#
# Running upgrade on {args.env_name} at {timestamp}
#"""
    log(header, config['overlay_path'])

    # 2025.2.0 updates
    log('Checking 2025.2.0 updates', config['overlay_path'])
    update_secrets_2025_2_0(config['overlay_path'], config['source_path'])
    update_apps_2025_2_0(config['overlay_path'], def_overlay_path)

    # 2025.2.1 updates
    log('Checking 2025.2.1 updates', config['helm_env_path'])
    update_secrets_2025_2_1(config['helm_env_path'])

    # 2026.1.0 updates
    log('Checking 2026.1.0 updates', config['overlay_path'])
    update_secrets_2026_1_0(config['overlay_path'], config['source_path'])

    footer=f"""#
# End upgrade on {args.env_name} at {timestamp}
#"""
    log(footer, config['overlay_path'])
