FROM gcr.io/forgerock-io/am-cdk:7.5.0

ARG CONFIG_PROFILE=cdk
RUN echo "\033[0;36m*** Building '${CONFIG_PROFILE}' profile ***\033[0m"
COPY  --chown=forgerock:root config-profiles/${CONFIG_PROFILE}/ /home/forgerock/openam/

COPY --chown=forgerock:root *.sh /home/forgerock/

RUN mkdir -p /home/forgerock/logging

ENV CATALINA_OPTS="${CATALINA_OPTS} -Dlogback.configurationFile=/home/forgerock/logging/logback.xml"

WORKDIR /home/forgerock

# If you want to debug AM uncomment these lines:
#ENV JPDA_TRANSPORT=dt_socket
#ENV JPDA_ADDRESS *:9009
