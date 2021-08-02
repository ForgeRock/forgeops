FROM gcr.io/forgerock-io/ig/pit1:7.1.1-9ffb8c9af465521971f8404b903a64be19a44cd2

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
