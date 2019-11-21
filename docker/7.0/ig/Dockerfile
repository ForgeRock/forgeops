FROM gcr.io/forgerock-io/ig/pit1:7.0.0-23c6661e7030e7ba24dd5b7d8a3d26bdd70101c3

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
