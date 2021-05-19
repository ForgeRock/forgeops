FROM gcr.io/forgerock-io/ig/pit1:7.2.0-21e48d900dd8cf92918d3f8322ad4786ff1ae930

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
