# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds:7.0.0-aeb3858b272aad86ac0ca2f33501bb2bbc540af4

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
