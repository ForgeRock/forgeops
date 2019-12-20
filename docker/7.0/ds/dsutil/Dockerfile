# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-7dd37a8e20fc05c8a88cf1a02ef5d4b3a5092c38

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
