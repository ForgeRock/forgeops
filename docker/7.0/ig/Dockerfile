FROM gcr.io/forgerock-io/ig:7.0.0-19589537018942e60b0fa49dc1d79c6c211b2226

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
