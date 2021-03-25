FROM gcr.io/forgerock-io/ig/pit1:7.1.0-daa97420ed6b89a53f74ef91f63c78a1dcddde1f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
