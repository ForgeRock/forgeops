FROM gcr.io/forgerock-io/ig/pit1:7.1.3-24a092ed60e92564229f01f314ed47d60ba7aabc

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
