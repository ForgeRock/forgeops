FROM gcr.io/forgerock-io/ig/pit1:7.2.0-74670e3719f8224a2d43b94491480bbb4d800b00

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
