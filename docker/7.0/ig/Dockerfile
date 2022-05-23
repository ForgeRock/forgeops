FROM gcr.io/forgerock-io/ig/pit1:7.1.3-5e0b02f6c648836a51cddc6954a157a545085b72

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
