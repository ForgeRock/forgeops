FROM gcr.io/forgerock-io/am-config-upgrader/pit1:7.1.0-9928c3573118a7ac2bf3958340c61f7b28540fe8

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