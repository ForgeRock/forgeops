FROM gcr.io/forgerock-io/ig/pit1:7.1.2-c5d40684a1e1a42d40785ca95c7fde5e4a8208c3

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
