FROM gcr.io/forgerock-io/ig/pit1:7.1.3-fdb8b065ee122a4012d62f8bc038194524ff7f7e

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
