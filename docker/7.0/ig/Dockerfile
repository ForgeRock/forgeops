FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-a4da3dccad7f33aae4d5df537354996a8921cebb

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
