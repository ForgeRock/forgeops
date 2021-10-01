FROM gcr.io/forgerock-io/ig/pit1:7.1.2-3b185074506507b2eebff0ab8bdce95793ccfbde

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
