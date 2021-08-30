FROM gcr.io/forgerock-io/ig/pit1:7.1.1-819b89b3e99c459236bb9f519ad1b7168f67866e

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
