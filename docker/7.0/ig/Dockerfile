FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-b8a0216095aa43b87c9a941f96ae8ef577feb6db

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
