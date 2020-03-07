# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds-empty:7.0.0-c8023812572ea39b1ea02ec1bb22a18d6b076b77

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
