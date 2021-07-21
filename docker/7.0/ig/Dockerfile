FROM gcr.io/forgerock-io/ig/pit1:7.2.0-2021.7-3474f8f5746f1fe1ddeb0c754b2e16305398202c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
