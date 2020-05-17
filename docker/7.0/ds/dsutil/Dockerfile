# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds-empty:7.0.0-ff04c9739d798eb4562428df323c30f1a587e90b

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
