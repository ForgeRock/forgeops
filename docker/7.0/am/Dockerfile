FROM gcr.io/forgerock-io/am-base/pit1:7.0.0-d0de590dcfb540d5a75161225b842622c73ce647
#FROM gcr.io/forgerock-io/am-base/pit1:7.0.0-d0de590dcfb540d5a75161225b842622c73ce647
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
