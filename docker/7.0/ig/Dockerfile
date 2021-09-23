FROM gcr.io/forgerock-io/ig/pit1:7.1.1-0e04052ccdad6777933eadf4b0d945ba4650d85b

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
