FROM gcr.io/forgerock-io/ig/pit1:7.1.0-62b34649549eab3f8c4bd3e0b44fad2ed64b4198

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
