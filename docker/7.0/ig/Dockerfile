FROM gcr.io/forgerock-io/ig:7.1.0-469e85a6fb43fba998bffaf105fa1a6147bf58e7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
