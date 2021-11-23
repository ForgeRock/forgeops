FROM gcr.io/forgerock-io/ig/pit1:7.1.2-c4701ebedf540c7b19dde564cd1632a4797bcceb

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
