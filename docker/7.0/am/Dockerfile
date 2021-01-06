FROM gcr.io/forgerock-io/am-base/pit1:7.1.0-fd24c1767494660713e0a0083ba47b0b6285db69
USER root

ENV DEBIAN_FRONTEND=noninteractive                          
ENV APT_OPTS="--no-install-recommends --yes"                
RUN apt-get update \                                        
        && apt-get install -y git \           
        && apt-get clean \                                  
        && rm -r /var/lib/apt/lists /var/cache/apt/archives 

USER forgerock

# IAM-434: Preserves the native XUI code in a new location specifically for OAuth 2-related UI needs.
RUN cp -R /usr/local/tomcat/webapps/am/XUI /usr/local/tomcat/webapps/am/OAuth2_XUI
ENV CATALINA_USER_OPTS -Dorg.forgerock.am.oauth2.consent.xui_path=/OAuth2_XUI

COPY  --chown=forgerock:root config/ /home/forgerock/openam/config/

# Use a custom logback. Comment out if you want to use the default json logger.
COPY --chown=forgerock:root logback.xml /usr/local/tomcat/webapps/am/WEB-INF/classes

COPY --chown=forgerock:root *.sh /home/forgerock/

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
