FROM gcr.io/forgerock-io/ig/pit1:7.1.2-095e7c8d1b6ce3a28f07ff86e14a7853cc92b754

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
