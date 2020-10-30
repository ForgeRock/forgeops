FROM gcr.io/forgerock-io/ig/pit1:7.1.0-423cccfc6780c7b10ba03162640d7eedc8c80bae

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
