FROM gcr.io/forgerock-io/ig/pit1:7.2.0-8046aaa84aa29b4f26feea3d501127f0ce772e62

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
