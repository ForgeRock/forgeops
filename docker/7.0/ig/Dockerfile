FROM gcr.io/forgerock-io/ig/pit1:7.1.2-54dc241cb4965fadbf75e435ef252af87116172e

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
