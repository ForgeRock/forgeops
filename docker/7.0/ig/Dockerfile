FROM gcr.io/forgerock-io/ig/pit1:7.0.0-c8e89c0138b49adeb200fd153d446644df5ff7e9

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
