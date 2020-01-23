FROM gcr.io/forgerock-io/ig:7.0.0-628837a6cd90c4a79b066ad8349c5f6152c54446

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
