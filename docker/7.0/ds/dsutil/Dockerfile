# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds-empty:7.0.0-5b1b0373e22848c4d70c059cb26175f83892b1c8

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
