FROM gcr.io/forgerock-io/ig/pit1:7.1.0-a1249b6ca859fe142518b49dbf4cb2ca6eefd910

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
