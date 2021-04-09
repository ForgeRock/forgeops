# Utility ds image for testing, benchmarking, etc.
# Also useful as a general purpose debugging tool
FROM gcr.io/forgerock-io/ds:7.1.0-2021-2-f8cf8c73a323ad27fef00bf59b08330d99d0e50d

USER root
ENV DEBIAN_FRONTEND=noninteractive                           
ENV APT_OPTS="--no-install-recommends --yes"                 
RUN apt-get update \                                         
        && apt-get install -y bash vim curl dnsutils procps netcat  \                          
        && apt-get clean \                                   
        && rm -r /var/lib/apt/lists /var/cache/apt/archives  


COPY --chown=forgerock:root bin/*  bin/
COPY --chown=forgerock:root ds-idrepo.template config/MakeLDIF

# reset entrypoint of ds container
ENTRYPOINT []
CMD ["bash"]
