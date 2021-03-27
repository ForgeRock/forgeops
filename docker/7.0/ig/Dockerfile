FROM gcr.io/forgerock-io/ig/pit1:7.1.0-61b0d38c7ab7337e91a44eaca252bfd1a3ca2cc4

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
