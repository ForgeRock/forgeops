FROM gcr.io/forgerock-io/ig/pit1:7.1.2-704437addf92587676e6b6fe49f2ca3885c4ff01

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
