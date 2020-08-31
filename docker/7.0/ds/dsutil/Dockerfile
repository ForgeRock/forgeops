# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds/pit1:7.1.0-b2412d065d7b2cd25a397ad37b3d40b49975d19f

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
