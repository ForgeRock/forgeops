FROM gcr.io/forgerock-io/ig/pit1:7.1.2-308fafdff1b3a7694c8f9fc03afd00c45c72ba22

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
