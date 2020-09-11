# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds/pit1:7.0.0-PAAS-GA-69556e933f5306cd8d16c053ad10ac5a46607782

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
