FROM gcr.io/forgerock-io/ig:7.0.0-a51b677a020444167c99b798663f9d9f79606a49

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
