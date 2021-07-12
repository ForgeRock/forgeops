FROM gcr.io/forgerock-io/ig/pit1:7.2.0-2021.7-61d4845627a4dec79a79fe76517df15499188915

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
