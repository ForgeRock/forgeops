FROM gcr.io/forgerock-io/ig:7.0.0-bf890bfcede87c970867f42a2969d59647ec5fa2

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
