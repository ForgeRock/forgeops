FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-194248fa2e9be84691f5a79d3558b7988b6f9f16

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
