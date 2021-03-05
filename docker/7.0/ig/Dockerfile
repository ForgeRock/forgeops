FROM gcr.io/forgerock-io/ig/pit1:7.1.0-514a4ed12323274d4d5ac98f88ea4b0b2222ab0b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
