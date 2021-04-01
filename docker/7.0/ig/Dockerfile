FROM gcr.io/forgerock-io/ig/pit1:7.1.0-4f14671096f6e1d5716a9dd1e7a1542a064c0724

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
