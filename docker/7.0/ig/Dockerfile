FROM gcr.io/forgerock-io/ig/pit1:7.1.3-7f5f4528a44fbbb4e66b02f812a286c4013f72d2

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
