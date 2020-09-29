FROM gcr.io/forgerock-io/ig/pit1:7.1.0-ac960e819fbe40277e87807f052ec47b9d04b5b7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
