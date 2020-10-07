FROM gcr.io/forgerock-io/am-config-upgrader/docker-build@sha256:e98feb8a98a099d4dd3cef2e0b7c991cdfaa07821e42c9a1099c9db0d0ffcb5c

USER root

COPY --chown=forgerock:root export.sh "$FORGEROCK_HOME"/
COPY --chown=forgerock:root config/ /am-config/config
COPY --chown=forgerock:root rules/ /rules
COPY --chown=forgerock:root custom-entrypoint.sh "$FORGEROCK_HOME"/

USER 11111

CMD "$FORGEROCK_HOME/custom-entrypoint.sh"