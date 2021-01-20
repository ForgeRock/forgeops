FROM gcr.io/forgerock-io/am-config-upgrader/pit1:7.1.0-2020-17-ad8f1e11f2f21f4d6880f51cdbc2f8038c8e84c8

USER root

COPY --chown=forgerock:root export.sh "$FORGEROCK_HOME"/
COPY --chown=forgerock:root config/ /am-config/config
COPY --chown=forgerock:root rules/ /rules
COPY --chown=forgerock:root custom-entrypoint.sh "$FORGEROCK_HOME"/

USER 11111

CMD "$FORGEROCK_HOME/custom-entrypoint.sh"