FROM gcr.io/forgerock-io/ig:7.0.0-e5af5236e1f2ed29c4de0c58948430f56dbd41e4

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
