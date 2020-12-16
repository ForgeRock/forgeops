FROM gcr.io/forgerock-io/am-config-upgrader:7.1.0-4620b7299064d0d2441c829ea7d46e7390e85e2a

USER root

COPY --chown=forgerock:root export.sh "$FORGEROCK_HOME"/
COPY --chown=forgerock:root config/ /am-config/config
COPY --chown=forgerock:root rules/ /rules
COPY --chown=forgerock:root custom-entrypoint.sh "$FORGEROCK_HOME"/

USER 11111

CMD "$FORGEROCK_HOME/custom-entrypoint.sh"