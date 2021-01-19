FROM gcr.io/forgerock-io/ig/pit1:7.1.0-1978a4a291443c0346cbbf5925a548df6032238b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
