FROM gcr.io/forgerock-io/ig/pit1:7.1.0-f87f12af0c77c8d546dfc77a2538445db6bf8251

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
