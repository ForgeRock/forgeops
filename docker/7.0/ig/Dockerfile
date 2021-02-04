FROM gcr.io/forgerock-io/ig/pit1:7.1.0-8f928b69f699054cd792c5a5fc3570a1dc3a87dd

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
