FROM gcr.io/forgerock-io/am-base/pit1:7.0.0-8301e3d99fe410cf1e89a32e02a6c60b9b9a4d5d
#FROM gcr.io/forgerock-io/am-base/pit1:7.0.0-8301e3d99fe410cf1e89a32e02a6c60b9b9a4d5d
USER root

RUN apt-get update && apt-get install -y git

USER forgerock

COPY  --chown=forgerock:root config/ /home/forgerock/openam/config/

# Use a custom logback. Comment out if you want to use the default json logger.
COPY logback.xml /usr/local/tomcat/webapps/am/WEB-INF/classes

COPY custom-entrypoint.sh /home/forgerock

WORKDIR /home/forgerock/openam

# This lets the user see what FBC files have been modified
RUN git config --global user.email "cloud-deployment@forgerock.com" && \
    git config --global user.name "Cloud Deployment" && \
    git add . && \
    git commit -m "CDM file-based configuration overlay"

WORKDIR /home/forgerock

# If you want to debug AM uncomment these lines:
#ENV JPDA_TRANSPORT=dt_socket
#ENV JPDA_ADDRESS *:9009

ENTRYPOINT ["/home/forgerock/custom-entrypoint.sh"]
