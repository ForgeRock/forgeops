FROM gcr.io/forgerock-io/ig/pit1:7.1.2-b0b9e2da9c3de96085985b9f1e4aa767894d0d85

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
