FROM gcr.io/forgerock-io/am-config-upgrader/pit1:7.1.0-03b4415d943808e7ed456657260e3c9c55cfb9ae

USER root

RUN apt-get update && apt-get install -y procps \
        && apt-get clean && rm -r /var/lib/apt/lists /var/cache/apt/archives
COPY --chown=forgerock:root tar-config.sh "$FORGEROCK_HOME"/
COPY --chown=forgerock:root config/ /am-config/config
COPY --chown=forgerock:root rules/ /rules
COPY --chown=forgerock:root custom-entrypoint.sh "$FORGEROCK_HOME"/
RUN rm -f /rules/latest.groovy

USER 11111

CMD "$FORGEROCK_HOME/custom-entrypoint.sh"