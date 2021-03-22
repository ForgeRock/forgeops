FROM gcr.io/forgerock-io/am-config-upgrader:7.1.0-2021-1-29155fe41fe98f68d9afb5558441f110406bfc52

USER root

RUN apt-get update && apt-get install -y procps
COPY --chown=forgerock:root tar-config.sh "$FORGEROCK_HOME"/
COPY --chown=forgerock:root config/ /am-config/config
COPY --chown=forgerock:root rules/ /rules
COPY --chown=forgerock:root custom-entrypoint.sh "$FORGEROCK_HOME"/

USER 11111

CMD "$FORGEROCK_HOME/custom-entrypoint.sh"