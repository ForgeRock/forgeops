FROM gcr.io/forgerock-io/ig/pit1:7.1.0-15014b0affee17dc64db29aab9893453d046eb88

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
