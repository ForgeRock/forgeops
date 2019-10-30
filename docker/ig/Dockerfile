FROM gcr.io/forgerock-io/ig/pit1:7.0.0-ad7685d53263df261766b93872ad7b25af6bbee5

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
