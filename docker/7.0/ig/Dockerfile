FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-e669f137605ba7597b7554c6d953d3b0c4774391

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
