FROM gcr.io/forgerock-io/ig:7.0.0-da8435ab21ab098fc472fbf195503a79e5d555a7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
