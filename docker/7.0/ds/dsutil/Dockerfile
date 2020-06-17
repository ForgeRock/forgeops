# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-3e928f77855a379bb1e2f2f6ed4485dd0aa064c5

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
