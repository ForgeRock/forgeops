FROM gcr.io/forgerock-io/ig/pit1:7.1.2-d66abb69c699ec49387189452e4c4c3500b2b6cd

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
