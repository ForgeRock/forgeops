FROM gcr.io/forgerock-io/ig/pit1:7.1.0-a8863009e73d07aa66699708b8e8aa19b55ab1cc

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
