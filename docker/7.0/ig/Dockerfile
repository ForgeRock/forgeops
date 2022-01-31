FROM gcr.io/forgerock-io/ig/pit1:7.1.2-a82bbfe8b5205b9ff03136f5bc2184cacc6b5a16

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
