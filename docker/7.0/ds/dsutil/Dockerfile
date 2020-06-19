# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds-empty:7.0.0-095a2cf13c1e0d2baed14f999247f1195a00bd40

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
