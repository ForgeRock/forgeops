FROM gcr.io/forgerock-io/ig/pit1:7.1.2-08c6105b07b32a880f11d078b053fc60b26a5266

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
