FROM gcr.io/forgerock-io/ig/pit1:7.1.0-800b62be00d9d5e0cc3e59a16ccfa0e8f0233f6f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
