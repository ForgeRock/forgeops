FROM gcr.io/forgerock-io/ig/pit1:7.1.2-64ebc7c90eb4256e8886a17f51ce36ac3b5a0d91

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
