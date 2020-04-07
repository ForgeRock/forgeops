FROM outillage/commitsar:latest as commitsar
FROM debian:sid-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
        && apt-get install --yes --no-install-recommends \
                           shellcheck \
                           make \
                           git \
                           python3-minimal \
                           python3-pip \
                           python3-setuptools \
                           npm

COPY --from=commitsar /usr/local/bin/commitsar /usr/local/bin/commitsar
COPY docker/cli-tools/repo/src /opt/workspace
RUN cd /opt/workspace && pip3 install .
RUN npm install -g tslint typescript
WORKDIR /opt/workspace
