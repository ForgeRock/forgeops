FROM gcr.io/forgerock-io/ig/pit1:7.2.0-619bea6ee03146c09fc5e4fd4e6eee2069f1ac31

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
