FROM gcr.io/forgerock-io/ig/pit1:7.1.2-3cc341af6cf04d0ad97cc9a3226a2172e8717090

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
