FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-b1c5a6124a8fcf54e78d2fabe749836d904776ce

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
