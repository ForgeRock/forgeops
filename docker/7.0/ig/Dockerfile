FROM gcr.io/forgerock-io/ig/pit1:7.1.2-88893b498bd8eb0b1efd30aa63a02762aefa3f52

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
