FROM gcr.io/forgerock-io/ig/pit1:7.1.2-2f5e0ad0a99abe25953159bf6614e1b45cf7fb06

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
