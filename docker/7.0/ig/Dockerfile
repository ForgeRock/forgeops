FROM gcr.io/forgerock-io/ig/pit1:7.0.0-5b421c297e2c44a9a45ffd35ea703267f1bd1c0f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
