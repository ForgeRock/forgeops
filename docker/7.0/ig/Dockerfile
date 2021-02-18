FROM gcr.io/forgerock-io/ig/pit1:7.1.0-ab8300bb8644cd512e3b14c1a4a2a134ad37fbaa

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
