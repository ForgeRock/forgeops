FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-7351251a4bda73f085e33db4373178ca0c993292

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
