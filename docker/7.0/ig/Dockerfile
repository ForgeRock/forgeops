FROM gcr.io/forgerock-io/ig/pit1:7.2.0-2021.7-337a1161a904dde8dab7054d7a1b99d0061ee80c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
