FROM gcr.io/forgerock-io/ig/pit1:7.1.0-8f4a876bf49f4a9fcddc99ee0a4d46637e058ee1

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
