FROM gcr.io/forgerock-io/ig/pit1:7.1.2-b80928ff302b1cf0aa73a6f09b22fc3f3a390d57

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
