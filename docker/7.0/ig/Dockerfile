FROM gcr.io/forgerock-io/ig/pit1:7.2.0-980258266f522e5a6bc33e92a61e08b3e35bd094

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
