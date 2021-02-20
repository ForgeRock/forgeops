# Utility ds image for testing, benchmarking, etc.
# Also useful as a general purpose debugging tool
FROM gcr.io/forgerock-io/ds/pit1:7.1.0-12a1c5e6a53c6b454c9325706b136b9b1b0fec84

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
