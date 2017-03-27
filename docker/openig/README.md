# Dockerfile for OpenIG

To build:

docker build -t forgerock/openig:latest . 

To run:

docker run -p 8080:8080 -it forgerock/openig

To use the sample configuration, mount the samples-config directory on /var/openig in the container:

docker run --rm -p 28080:8080 -v `pwd`/sample-config:/var/openig -it forgerock/openig

(Also see the sample docker-compose.yaml file for an example.)

## Sample configuration to test OpenIG 

### Sample 1) Policy Enforcement

Route configuration file: 01-pep.json

As a prerequisite, you need a fully functional OpenAM installation with a policy agent configuration used by OpenIG. The following environment variables must be set:
OPENAM_URL 
POLICY_ADMIN
POLICY_ADMIN_PWD
(TODO: How to set those in when starting the Docker image?)

Point your web browser to <baseURL>/pep - you should be redirected to OpenAM for authentication. Authorization policies determine whether you are allowed to get to the (static) page or not.

### Sample 2) Throttling

Route configuration file: 20-simplethrottle.json

Point your client to <baseURL>/simplethrottle. The global throttling rate can be modified in the route configuration file.

### Sample 3) ElasticSearch

Route configuration file: 30-elasticsearch.json

Set the ElasticSearch connection parameters - host and port - in the route configuration file. Also, make sure you set the appropriate indexes in ElasticSearch.

Point your client to  <baseURL>/elasticsearch - this generates audit events in ElasticSearch.



