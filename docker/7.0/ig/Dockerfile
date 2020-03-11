FROM gcr.io/forgerock-io/ig:7.0.0-0bfe1d8444b12c1292c41e80c3b1aeed14e8bd89

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
