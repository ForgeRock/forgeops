import base64
from flask import Flask, request
import os
import sys
import datetime
import logging

import google.auth
from google.auth.transport.requests import AuthorizedSession
from flask import Flask, request
import requests

logging.basicConfig(stream=sys.stdout, level=logging.INFO)
log = logging.getLogger('gcr-pruner')
log.info('initializing gcr pruner')

# dont actually delete
DRY_RUN = bool(int(os.environ.get('GCR_PRUNE_DRY_RUN', 0)))
# export MAX_UPDATE_AGE=DAYS maximum age of a digest
# (delete if currrent_time - last_update > MAX_UPDATE_AGE)
MAX_AGE = datetime.timedelta(int(os.environ.get('MAX_UPDATE_AGE', 14)))

REGISTRY_BASE = 'https://gcr.io/v2'
try:
    credentials, project = google.auth.default(scopes=['https://www.googleapis.com/auth/cloud-platform'])
    authed_session = AuthorizedSession(credentials)
    app = Flask(__name__)
except Exception as e:
    log.error(e)
    sys.stdout.flush()

EXCLUDE = { "engineering-devops/agent", "engineering-devops/am",
   "engineering-devops/am-base", "engineering-devops/am/cache",
   "engineering-devops/am/docker-build", "engineering-devops/ampwdgen",
   "engineering-devops/ampwdgen/cache", "engineering-devops/amster",
   "engineering-devops/amster-base", "engineering-devops/amster/cache",
   "engineering-devops/andrew/am", "engineering-devops/andrew/amster",
   "engineering-devops/andrew/ds-cts", "engineering-devops/andrew/ds-idrepo",
   "engineering-devops/andrew/forgeops-secrets",
   "engineering-devops/andrew/idm", "engineering-devops/apache-agent",
   "engineering-devops/argocd", "engineering-devops/bench-client",
   "engineering-devops/benchmark", "engineering-devops/cdk-cli",
   "engineering-devops/certs/tls",
   "engineering-devops/cloud1865/forgeops-secrets",
   "engineering-devops/config-util", "engineering-devops/dashboard-smoketests",
   "engineering-devops/downloader", "engineering-devops/ds",
   "engineering-devops/ds-base", "engineering-devops/ds-base/docker-build",
   "engineering-devops/ds-base6_5", "engineering-devops/ds-cts",
   "engineering-devops/ds-cts/cache", "engineering-devops/ds-empty",
   "engineering-devops/ds-empty/docker-build", "engineering-devops/ds-idrepo",
   "engineering-devops/ds-idrepo/cache",
   "engineering-devops/ds-internal/docker-build",
   "engineering-devops/ds/docker-build", "engineering-devops/dsutil",
   "engineering-devops/end-user-ui", "engineering-devops/fbc-space/am",
   "engineering-devops/fbc-space/config-util",
   "engineering-devops/fbc-space/ds-cts",
   "engineering-devops/fbc-space/ds-idrepo",
   "engineering-devops/fbc-space/forgeops-tests",
   "engineering-devops/fbc-space/idm", "engineering-devops/fbc-space/ig",
   "engineering-devops/forgeops-cli", "engineering-devops/forgeops-secrets",
   "engineering-devops/forgeops-secrets/cache",
   "engineering-devops/forgeops-tests", "engineering-devops/forgeopsui",
   "engineering-devops/forgerock/products/amster",
   "engineering-devops/forgerock/products/openam",
   "engineering-devops/forgerock/products/opendj",
   "engineering-devops/gandru/ds", "engineering-devops/gandru/ds-cts",
   "engineering-devops/gandru/ds-idrepo",
   "engineering-devops/gandru/forgeops-secrets",
   "engineering-devops/gandru/overseer",
   "engineering-devops/gandru/overseer-0",
   "engineering-devops/gandru/overseer-a", "engineering-devops/gary/am",
   "engineering-devops/gary/amster", "engineering-devops/gary/ds-cts",
   "engineering-devops/gary/ds-idrepo",
   "engineering-devops/gary/forgeops-secrets", "engineering-devops/gary/idm",
   "engineering-devops/gary/ig", "engineering-devops/gatling",
   "engineering-devops/gceme", "engineering-devops/git",
   "engineering-devops/google-cloud", "engineering-devops/grafana/auto-import",
   "engineering-devops/gsutil", "engineering-devops/helm",
   "engineering-devops/hidekuro_drupod", "engineering-devops/idm",
   "engineering-devops/idm-base", "engineering-devops/idm-base6_5",
   "engineering-devops/idm/cache", "engineering-devops/ig",
   "engineering-devops/ig-base", "engineering-devops/ig/cache",
   "engineering-devops/ingress/cert", "engineering-devops/java",
   "engineering-devops/java/cache", "engineering-devops/kibana-tests",
   "engineering-devops/lee/app-operator", "engineering-devops/locust",
   "engineering-devops/lodestar-images/am",
   "engineering-devops/lodestar-images/amster",
   "engineering-devops/lodestar-images/config-util",
   "engineering-devops/lodestar-images/ctsstore",
   "engineering-devops/lodestar-images/ds-config",
   "engineering-devops/lodestar-images/ds-cts",
   "engineering-devops/lodestar-images/ds-idrepo",
   "engineering-devops/lodestar-images/ds-idrepo/ds-config",
   "engineering-devops/lodestar-images/ds-idrepo/ds-cts",
   "engineering-devops/lodestar-images/forgeops-secrets",
   "engineering-devops/lodestar-images/forgeops-tests",
   "engineering-devops/lodestar-images/gcr.io/k8s-skaffold/ds-ctsstore",
   "engineering-devops/lodestar-images/gcr.io/k8s-skaffold/ds-userstore",
   "engineering-devops/lodestar-images/idm",
   "engineering-devops/lodestar-images/ig",
   "engineering-devops/lodestar-images/overseer",
   "engineering-devops/lodestar-images/userstore",
   "engineering-devops/lodestarbox", "engineering-devops/lodestarbox-dev",
   "engineering-devops/ltest/am", "engineering-devops/ltest/amster",
   "engineering-devops/ltest/idm", "engineering-devops/microgateway",
   "engineering-devops/ms-authn", "engineering-devops/ms-load-test",
   "engineering-devops/ms-token-exchange",
   "engineering-devops/ms-token-validation", "engineering-devops/nginx-agent",
   "engineering-devops/nginx-fancyindex", "engineering-devops/nsaxena/am",
   "engineering-devops/nsaxena/amster", "engineering-devops/nsaxena/ds-cts",
   "engineering-devops/nsaxena/ds-idrepo", "engineering-devops/nsaxena/idm",
   "engineering-devops/ntemp/overseer", "engineering-devops/openam",
   "engineering-devops/openidm", "engineering-devops/openidm-postgres",
   "engineering-devops/openig", "engineering-devops/pentest-app",
   "engineering-devops/perfdebugboxes/am",
   "engineering-devops/perfdebugboxes/ds",
   "engineering-devops/perfdebugboxes/idm", "engineering-devops/perfteam/am",
   "engineering-devops/perfteam/ds", "engineering-devops/perfteam/idm",
   "engineering-devops/perftoolbox", "engineering-devops/phill/am",
   "engineering-devops/phill/amster", "engineering-devops/phill/ds-cts",
   "engineering-devops/phill/ds-idrepo",
   "engineering-devops/phill/forgeops-secrets", "engineering-devops/phill/idm",
   "engineering-devops/ptest/am", "engineering-devops/ptest/amster",
   "engineering-devops/ptest/config-util", "engineering-devops/ptest/ds-cts",
   "engineering-devops/ptest/ds-idrepo",
   "engineering-devops/ptest/forgeops-tests", "engineering-devops/ptest/idm",
   "engineering-devops/ptest/ig", "engineering-devops/ptest/lodestarbox",
   "engineering-devops/ptest/toolbox", "engineering-devops/pulumi-nodejs",
   "engineering-devops/pulumi-nodejs-docker", "engineering-devops/python-test",
   "engineering-devops/pyutil", "engineering-devops/report-dashboard",
   "engineering-devops/riso/agent", "engineering-devops/riso/agent-app",
   "engineering-devops/riso/am", "engineering-devops/riso/amster",
   "engineering-devops/riso/config-util", "engineering-devops/riso/ds-cts",
   "engineering-devops/riso/ds-idrepo",
   "engineering-devops/riso/ingress-agent",
   "engineering-devops/riso/web-pages", "engineering-devops/sk-am",
   "engineering-devops/sk-amster", "engineering-devops/sk-idm",
   "engineering-devops/sk-ig", "engineering-devops/sk-lee/am",
   "engineering-devops/sk-lee/amster", "engineering-devops/sk-lee/amster-cdm",
   "engineering-devops/sk-lee/amster-smoke",
   "engineering-devops/sk-lee/config-util", "engineering-devops/sk-lee/ds-cts",
   "engineering-devops/sk-lee/ds-idrepo",
   "engineering-devops/sk-lee/ds-idrepro", "engineering-devops/sk-lee/dsutil",
   "engineering-devops/sk-lee/forgeops-secrets",
   "engineering-devops/sk-lee/gatling", "engineering-devops/sk-lee/idm",
   "engineering-devops/sk-lee/ig", "engineering-devops/sk-phill/am",
   "engineering-devops/sk-phill/amster", "engineering-devops/sk-phill/ds-cts",
   "engineering-devops/sk-phill/ds-idrepo", "engineering-devops/sk-phill/idm",
   "engineering-devops/skaffold", "engineering-devops/skaffold/cache",
   "engineering-devops/skaffold/dev/am",
   "engineering-devops/skaffold/dev/amster",
   "engineering-devops/skaffold/dev/idm",
   "engineering-devops/skaffold/idm-am-common-user/amster",
   "engineering-devops/skaffold/idm-am-common-user/idm",
   "engineering-devops/skaffold/oauth2/amster",
   "engineering-devops/skaffold/oauth2/end-user-ui",
   "engineering-devops/skaffold/oauth2/idm",
   "engineering-devops/skaffold/oauth2/openam",
   "engineering-devops/skaffold/oauth2/rs",
   "engineering-devops/terminator-demoapp", "engineering-devops/test-cron-job",
   "engineering-devops/test-shell", "engineering-devops/tomcat",
   "engineering-devops/tomh/am", "engineering-devops/tomh/amster",
   "engineering-devops/tomh/ds-cts", "engineering-devops/tomh/ds-idrepo",
   "engineering-devops/tomh/idm", "engineering-devops/toolbox",
   "engineering-devops/toolbox/cache", "engineering-devops/txu/am",
   "engineering-devops/txu/amster", "engineering-devops/txu/ds-cts",
   "engineering-devops/txu/ds-idrepo", "engineering-devops/txu/idm",
   "engineering-devops/util", "engineering-devops/warren-cloudshell",
   }

def repo_tags(repo):
    url = f'{REGISTRY_BASE}/{repo}/tags/list'
    response = authed_session.get(url)
    response.raise_for_status()
    return response.json().get('manifest')

def filter_digests(digests, max_recent_update_age):
    filtered = []
    for digest_id, digest_meta in digests.items():
        tagless = len(digest_meta['tag']) == 0
        last_update = datetime.datetime.utcfromtimestamp(
            int(digest_meta['timeUploadedMs']) / 1000.0000)
        stale =  datetime.datetime.now() - last_update > MAX_AGE
        log.debug(f'{digest_id} {last_update}')
        if tagless and stale:
            filtered.append(digest_id)
    num_digests = len(filtered)
    log.info(f'found {num_digests} to prune')
    return filtered

def registry_repos(exclude_images):
    response = authed_session.get(f'{REGISTRY_BASE}/_catalog')
    response.raise_for_status()
    repos = response.json()['repositories']
    return [ r for r in repos if r not in exclude_images]


def prune_manifests(repo, digest_ids, dry_run=DRY_RUN):
    for digest_id in digest_ids:
        url = f'{REGISTRY_BASE}/{repo}/manifests/{digest_id}'
        if dry_run:
            log.info(f'dry run: DELETE {url}')
        else:
            response = authed_session.delete(url)
            response.raise_for_status()
            log.info(f'DELETE {repo} {digest_id}')

def prune_registry(dry_run=DRY_RUN):
    log.info(f'is dry run {dry_run}')
    for repo in registry_repos(EXCLUDE):
        log.info(f'pruning {repo}')
        digests_to_remove = filter_digests(repo_tags(repo), 14)
        prune_manifests(repo, digests_to_remove, dry_run=dry_run)

@app.route('/', methods=['POST'])
def index():
    try:
        prune_registry()
    except requests.HTTPError as e:
        log.error(e)
        return e.response.reason, e.response.status_code
    except Exception as e:
        log.error(e)
        return f'Bad Request: {e}', 400
    # Flush the stdout to avoid log buffering.
    sys.stdout.flush()
    return ('', 204)

if __name__ == '__main__':
    prune_registry()
