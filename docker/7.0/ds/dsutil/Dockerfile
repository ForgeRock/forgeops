# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds:7.1.0-PAAS-GA-6903ff95b5ab68e4949d8e433f64ffec61ef0070

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
