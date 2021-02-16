FROM gcr.io/forgerock-io/am-config-upgrader/pit1:7.1.0-63a81a717e9a74aba948f5d55ebf79a6cb22b6c2

USER root

RUN apt-get update && apt-get install -y procps
COPY --chown=forgerock:root tar-config.sh "$FORGEROCK_HOME"/
COPY --chown=forgerock:root config/ /am-config/config
COPY --chown=forgerock:root rules/ /rules
COPY --chown=forgerock:root custom-entrypoint.sh "$FORGEROCK_HOME"/

USER 11111

CMD "$FORGEROCK_HOME/custom-entrypoint.sh"