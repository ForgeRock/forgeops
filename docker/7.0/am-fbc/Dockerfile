FROM gcr.io/forgerock-io/am/pit1:7.0.0-142335bfbb9bfb6fef9f8a47ec317bf90f5f5ee7

USER root
# musl is needed because the go code compiles in alpine.TODO: fix the go code
RUN apt-get update && apt-get install -y git musl jq
# ForgeRock user...
USER forgerock

RUN rm -rf /home/forgerock/openam && \
  mv /home/forgerock/openam-fbc /home/forgerock/openam

WORKDIR /home/forgerock/openam/config/services/realm/root

RUN rm \
  iplanetamplatformservice/1.0/globalconfig/default/com-sun-identity-servers/http___localhost_8080_am.json \
  sunamauthhotpservice/1.0/organizationconfig/default.json \
  iplanetamauthldapservice/1.0/organizationconfig/default.json

COPY logback.xml /usr/local/tomcat/webapps/am/WEB-INF/classes

#ENV CATALINA_OPTS "$CATALINA_OPTS -server -Dcom.sun.identity.configuration.directory=/home/forgerock/openam -Dcom.iplanet.services.stats.state=off -Djavax.net.ssl.trustStore=/var/run/secrets/truststore/cacerts -Djavax.net.ssl.trustStorePassword=changeit -Dcom.sun.identity.sm.sms_object_filebased_enabled=true -Dorg.forgerock.donotupgrade=true"
ENV CATALINA_OPTS "$CATALINA_OPTS -server -Djavax.net.ssl.trustStore=/var/run/secrets/truststore/cacerts -Djavax.net.ssl.trustStorePassword=changeit"

COPY --chown=forgerock:root am-entrypoint.sh /home/forgerock/am-entrypoint.sh

COPY --chown=forgerock:root config/ /home/forgerock/openam/config/
COPY --chown=forgerock:root --from=gcr.io/engineering-devops/go-util:7.0.0 /dist/ /usr/bin/

WORKDIR /home/forgerock/openam/config

# Debug kaniko build
#RUN find . -name \.wh\* -print

# Searches for any files that contain encrypted password fields and removes those fields
RUN find services -type f -name '*.json' -exec grep -l "-encrypted\"" {} \; | xargs -t -L 1 strip-encrypted-values

# Debug kaniko build
#RUN find . -name \.wh\* -print

# This lets the user see what FBC files have been modified
RUN git config --global user.email "cloud-deployment@forgerock.com" && \
    git config --global user.name "Cloud Deployment" && \
    git add . && \
    git commit -m "CDM file-based configuration overlay"

WORKDIR /home/forgerock

ENTRYPOINT /home/forgerock/am-entrypoint.sh