FROM gcr.io/forgerock-io/ig/pit1:7.1.2-b23b004c2ca8296fab4537a74edd37e80286cf15

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
