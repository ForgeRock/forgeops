# AM Dockerfile 


This is designed to be a flexible AM image that can be used in 
different deployment styles. 

If you have an existing configuration store, you can configure AM to use it by creating 
an appropriate boot.json file with boot passwords stored in keystore.jceks.


# Building

* The Dockerfile assumes that the openam.war file is pre-downloaded in this directory.


# Customizing the Web App 

If you wish to customize the AM web app, there are two strategies that you can use:

* Inherit FROM this image, and overlay your changes on /usr/local/tomcat/webapps/openam/
* Before you start AM, dynamically copy in the changes. This is the strategy used in the Helm charts. Set
 the CUSTOMIZE_AM variable to the path to a customization script. 

