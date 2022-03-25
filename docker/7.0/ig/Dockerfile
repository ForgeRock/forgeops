FROM gcr.io/forgerock-io/ig/pit1:7.1.2-8e27e0eb61f2a6b8c6c27bbdf17d16e4d24119d0

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
