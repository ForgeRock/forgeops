FROM gcr.io/forgerock-io/ig/pit1:7.1.0-d87b4a4c715fd7fa0a89202c93b4aca6aab36ba3

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
