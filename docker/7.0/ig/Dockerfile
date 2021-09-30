FROM gcr.io/forgerock-io/ig/pit1:7.1.2-9165ffb6f36dc8219987d2192fa2bda805e4f818

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
