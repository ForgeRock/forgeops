FROM gcr.io/forgerock-io/ig/pit1:7.0.0-0dca4996e549e74cb944141a0e176b3f7408256a

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
