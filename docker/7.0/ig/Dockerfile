FROM gcr.io/forgerock-io/ig/pit1:7.0.0-becf5885da967f144c48aa26db543a2d65ba882b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
