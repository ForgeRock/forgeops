FROM gcr.io/forgerock-io/ig/pit1:7.1.0-1596f814cac75f775c33310a0b24d6504b12b8c4

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
