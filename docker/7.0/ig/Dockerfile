FROM gcr.io/forgerock-io/ig/pit1:7.1.0-4817bd301bdb4758101d767a3e58d290649c256a

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
