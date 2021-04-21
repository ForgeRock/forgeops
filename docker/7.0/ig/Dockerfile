FROM gcr.io/forgerock-io/ig/pit1:7.2.0-1a7cf7db81e28088d027068fabdaeb7908e3bea9

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
