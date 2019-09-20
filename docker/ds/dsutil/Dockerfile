# Utility ds image for testing, etc.
FROM gcr.io/forgerock-io/ds-empty/docker-build:latest

COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
# Another option is to run some status command every N seconds?
CMD [ "-c", "sleep 10000000" ]
