FROM gcr.io/forgerock-io/ig/pit1:7.2.0-2021-7-11102f6a19c3be8c422dd219b142fc8f0e29132c

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
