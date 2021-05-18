FROM gcr.io/forgerock-io/ig/pit1:7.2.0-f7f65f8f92e25bdd6f83f67d651fa99cf5e3fba9

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
