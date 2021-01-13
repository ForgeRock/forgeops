FROM gcr.io/forgerock-io/ig/pit1:7.1.0-4a6871533294fa8888c750873acd65290b2d02a9

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
