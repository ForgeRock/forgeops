FROM gcr.io/forgerock-io/ig/pit1:7.2.0-fe8befcb9e6982be77e4fee93e576f462eb29fb0

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
