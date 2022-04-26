FROM gcr.io/forgerock-io/ig/pit1:7.1.3-1f75e4c81ae0375a723d1a9bad5626a221102191

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
