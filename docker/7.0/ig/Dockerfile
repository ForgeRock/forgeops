FROM gcr.io/forgerock-io/ig:7.0.0-ed6cd5133ea97d3a55e33626809a0626dcba8bf7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
