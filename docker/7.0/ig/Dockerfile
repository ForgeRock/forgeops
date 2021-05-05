FROM gcr.io/forgerock-io/ig/pit1:7.2.0-f6f1e677d34900f4f642ffe8c62f21944af0596e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
