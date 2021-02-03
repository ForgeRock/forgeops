FROM gcr.io/forgerock-io/ig/pit1:7.1.0-e0fdb04fb9bcaefdd2b50d655dd09af3c5d0fd25

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
