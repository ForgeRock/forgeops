FROM gcr.io/forgerock-io/ig/pit1:7.1.2-4475b9c023d62164bda9a018ebba8bd55456c0b5

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
