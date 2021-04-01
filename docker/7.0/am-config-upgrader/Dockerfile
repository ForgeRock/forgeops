FROM gcr.io/forgerock-io/am-config-upgrader/pit1:7.1.0-2021-1-0be719a4cebe8873af1e18202f49ab7e4daf52e1

USER root

RUN apt-get update && apt-get install -y procps
COPY --chown=forgerock:root tar-config.sh "$FORGEROCK_HOME"/
COPY --chown=forgerock:root config/ /am-config/config
COPY --chown=forgerock:root rules/ /rules
COPY --chown=forgerock:root custom-entrypoint.sh "$FORGEROCK_HOME"/

USER 11111

CMD "$FORGEROCK_HOME/custom-entrypoint.sh"