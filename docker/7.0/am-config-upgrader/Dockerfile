FROM gcr.io/forgerock-io/am-config-upgrader/pit1:7.1.0-08fb829e4f43cd0e0049e1f7d122e5cb94a00a44

USER root

COPY --chown=forgerock:root export.sh "$FORGEROCK_HOME"/
COPY --chown=forgerock:root config/ /am-config/config
COPY --chown=forgerock:root rules/ /rules
COPY --chown=forgerock:root custom-entrypoint.sh "$FORGEROCK_HOME"/

USER 11111

CMD "$FORGEROCK_HOME/custom-entrypoint.sh"