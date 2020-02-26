# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-94f5a1e356c1365a9f6e00ecbec3903e9c4db8f5

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
