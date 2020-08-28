# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds:7.1.0-691ebbf8dda3dca94931792af4592935d8825419

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
