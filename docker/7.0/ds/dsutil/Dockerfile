# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-811df5ce22a58995d94ad7f34e6552e9e8b4a8c0

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
