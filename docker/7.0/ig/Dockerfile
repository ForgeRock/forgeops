FROM gcr.io/forgerock-io/ig/pit1:7.0.0-95f94195022acdfa2ce8f2565839b2f6ed02eeda

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
