FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-60c40a35cae649a988c0a78d1de5ec1f895b4b9e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
