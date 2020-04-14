# AM Dockerfile 
This is designed to be a flexible AM image that can be used in different deployment styles. 

If you have an existing configuration store, you can configure AM to use it by creating 
an appropriate boot.json file with boot passwords stored in keystore.jceks.

# Customizing the Web App 
If you wish to customize the AM web app, you can inherit FROM this image, and 
overlay your changes on /usr/local/tomcat/webapps/am/.
 
# How to build am-base
In order to build this image you must provide the openam war file.
1. Log in to https://maven.forgerock.org/repo/webapp/#/login using your backstage account
2. Download the war file located in private-releases/org/forgerock/am/openam-server/<VERSION>/openam-server-<VERSION>.war
3. Rename the war file as `openam.war` and move it to the `am-base` folder

To build the image, run `docker build -t am-base .`

