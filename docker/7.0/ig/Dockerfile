FROM gcr.io/forgerock-io/ig/pit1:7.2.0-7717c3ee9ecdcfa2bedc5e337732bf605e526cb3

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
