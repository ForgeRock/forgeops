FROM gcr.io/forgerock-io/ig/pit1:7.0.0-f490fe6bc08bdbdb3ecf5b9a37c4786f6b0675e5

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
