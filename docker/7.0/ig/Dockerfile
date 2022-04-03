FROM gcr.io/forgerock-io/ig/pit1:7.1.2-3fd683c33cf5eed387c70403467618072e1a72ab

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
