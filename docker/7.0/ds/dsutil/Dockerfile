# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds:7.0.0-21db3310f337461b2ad06e3ba135420a20787084

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
