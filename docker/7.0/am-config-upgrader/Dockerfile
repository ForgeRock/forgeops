FROM gcr.io/forgerock-io/am-config-upgrader/pit1:7.1.0-ec0f331b1b02ee3dbeac5ba8a6969d5bdb336714

USER root

COPY --chown=forgerock:root export.sh "$FORGEROCK_HOME"/
COPY --chown=forgerock:root config/ /am-config/config
COPY --chown=forgerock:root rules/ /rules
COPY --chown=forgerock:root custom-entrypoint.sh "$FORGEROCK_HOME"/

USER 11111

CMD "$FORGEROCK_HOME/custom-entrypoint.sh"