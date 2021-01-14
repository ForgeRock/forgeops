FROM gcr.io/forgerock-io/am-config-upgrader/pit1:7.1.0-ba481ddf1e996a48ae746df3c8fc1e41f3a76e70

USER root

COPY --chown=forgerock:root export.sh "$FORGEROCK_HOME"/
COPY --chown=forgerock:root config/ /am-config/config
COPY --chown=forgerock:root rules/ /rules
COPY --chown=forgerock:root custom-entrypoint.sh "$FORGEROCK_HOME"/

USER 11111

CMD "$FORGEROCK_HOME/custom-entrypoint.sh"