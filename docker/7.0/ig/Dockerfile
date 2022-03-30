FROM gcr.io/forgerock-io/ig/pit1:7.1.2-7d802da69f0af5a124e3d46c12c33ead99f3e73e

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
