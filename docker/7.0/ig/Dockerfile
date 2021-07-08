FROM gcr.io/forgerock-io/ig/pit1:7.2.0-2ebc8e59507226862e6b150bb92d2981ade4b3cc

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
