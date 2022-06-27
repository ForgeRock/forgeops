FROM gcr.io/forgerock-io/ig/pit1:7.1.3-e67b72e618fe4bd6ec7a655fd3a5e986a13b88e5

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
