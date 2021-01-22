FROM gcr.io/forgeops-public/toolbox as tools
FROM debian:buster-slim
SHELL ["bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
        && apt-get install --yes --no-install-recommends \
                           make \
                           git \
                           python3-minimal \
                           python3-pip \
                           python3-setuptools

COPY src /opt/workspace
# source, source, ... destination
COPY --from=tools /usr/local/bin /usr/local/bin

RUN cd /opt/workspace && pip3 install .
WORKDIR /opt/workspace
