FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-fa641ca0d2070cd03ce6285ddd2b9b536af32b43

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
