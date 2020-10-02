FROM gcr.io/forgerock-io/ig/pit1:7.1.0-4dafca5e06430c04f2a7731ef25b5847190e8373

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
