FROM gcr.io/forgerock-io/ig/pit1:7.2.0-a2a5a6e8959ac555ab35e1ebea702eddd8b01802

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
