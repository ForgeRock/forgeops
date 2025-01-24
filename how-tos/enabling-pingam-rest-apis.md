# Enabling the PingAM REST API

## Objective
Enable the PingAM REST API in the PingAM UI.

## Limitation
* Currently this functionality isn't working in the current live PingAM version 7.5 but is fixed in the up and coming PingAM 8.0 release.  
  This can be tested by deploying the latest EA version of PingAM which is described below.
* The REST API explorer is disabled by default for security reasons and it is recommended to only enable in your development environment.

## Steps
* Select the latest EA version of the platform
`/path/to/forgeops/bin/forgeops image --release dev -e <your env> platform`

* Deploy the platform following the relevant instructions for Helm or Kustomize.

* In the PingAM UI, navigate to `CONFIGURE → GLOBAL SERVICES → REST APIs → API Descriptions`

* Select one of the options to enable the API and click `Save Changes`.

* Navigate to https://<your fqdn>/am/ui-admin/#api/explorer/

