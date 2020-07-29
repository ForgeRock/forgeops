# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds/pit1:7.0.0-017ff5fa70ff547a3bb7dada7f0ccd103a3d7b4e

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
