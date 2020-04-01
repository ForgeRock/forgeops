FROM gcr.io/forgerock-io/ig:7.0.0-bf129b1d79e3c7eb1b80a36a0f3c9ef5f39b570f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
