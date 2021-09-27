FROM gcr.io/forgerock-io/ig:7.2.0-2021-6-c5bf157a1400edc778b6171db49fa8038617050e

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
