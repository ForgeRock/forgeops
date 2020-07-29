FROM gcr.io/forgerock-io/ig/pit1:7.0.0-1c52695da57c583b412e6998bdd1448840795b4c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
