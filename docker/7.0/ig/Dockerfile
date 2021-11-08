FROM gcr.io/forgerock-io/ig/pit1:7.1.2-9440148ce6d1f828824a2c02a18d42e3ec8cddd8

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
