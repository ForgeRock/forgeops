# Auto Importing of Grafana Dashboards

This readme describes the contents of this folder along with instructions to rebuild the auto-upload  
container image and changing the core dashboards.

## Directory Contents
* **Dockerfile** used to create the container image used in the Kubernetes job for the auto import.
* **import-dashboards.sh** script executed in the above container image to carry out the formatting and import.
* **README.md** 

## How auto import works
As part of the forgerock-metrics helm chart, a Kubernetes job *(import-dash-job.yaml)* is triggered which  
executes the import process.  The steps are as follows(image runs import-dashboards.sh script):

1.  Waits until Grafana endpoint returns 200.
2.  Reads the dashboard files and formats them as required by the Grafana API.  Details of this are in the script.
3.  Imports formatted dashboards into Grafana.

## Creating a new auto import image
The following commands can be ran to create a new docker image used by the import-dashboards job.  
These instructions are for Google Container Registry:
* docker build -t gcr.io/engineering-devops/grafana/auto-import:\<version\> .
* gcloud docker -- push gcr.io/engineering-devops/grafana/auto-import:\<version\> .

If the image tag is changed, the tag needs to be updated in forgerock-metrics/values.yaml  
under grafanaDashboards.image.

## Dashboard files
The Grafana dashboard files can be located in the forgerock-metrics helm chart in the dashboards folder.  
These dashboard files are copied from the released ForgeRock 6.0.0 sample dashboards provided in the  
ForgeRock Download Center.  

Additional dashboards can either be:
* added to the dashboards/ folder prior to deployment.  Be aware that dashboards in different formats may not import  
correctly so check the logs of the import-dashboards job.
* imported, after deployment, via the Grafana GUI.  

Any updates or additions to these core dashboards will require new dashboards added to the dashboards/ folder  
and a new auto-import image built using the instructions in the previous section.


