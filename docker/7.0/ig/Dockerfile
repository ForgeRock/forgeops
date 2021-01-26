FROM gcr.io/forgerock-io/ig/pit1:7.1.0-89392a07bab3dfa5cf0accc017ef65b72e87b7f2

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
