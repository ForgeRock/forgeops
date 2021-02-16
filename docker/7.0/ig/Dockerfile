FROM gcr.io/forgerock-io/ig/pit1:7.1.0-253976f237081f225862f668d6663c231f958634

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
