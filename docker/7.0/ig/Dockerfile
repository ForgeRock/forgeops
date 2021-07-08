FROM gcr.io/forgerock-io/ig/pit1:7.2.0-b1d3d331a196b52695f1826892df6a0a93107de7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
