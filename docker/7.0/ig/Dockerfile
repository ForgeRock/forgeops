FROM gcr.io/forgerock-io/ig/pit1:7.1.2-76297ddbf91051074b157142c8e80054a34fdbb1

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
