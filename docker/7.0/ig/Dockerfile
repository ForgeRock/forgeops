FROM gcr.io/forgerock-io/ig-standalone:7.0.0-c9c9e810018d845e63c9817b7b9bf25c0de2f07c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
