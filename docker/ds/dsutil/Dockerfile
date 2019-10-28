# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds-empty:7.0.0-7ef42d9a34b5b829d10ca251e6a17d6eff93d678

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
