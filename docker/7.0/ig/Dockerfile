FROM gcr.io/forgerock-io/ig/pit1:7.0.0-9aec9f760f45999ef0715ef38a54bb4acb6387b2

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
