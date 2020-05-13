FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-5a240bfae2fe365aceb4b5e317e44e58c23fe0a6

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
