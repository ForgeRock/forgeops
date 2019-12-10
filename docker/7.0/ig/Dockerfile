FROM gcr.io/forgerock-io/ig:7.0.0-6777a0dd3d4bd72c7ec936403b8e6a86066bb1ed

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
