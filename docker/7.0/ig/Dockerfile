FROM gcr.io/forgerock-io/ig/pit1:7.1.0-7624837e4c5c2f1afc744f162180ed8a084aec70

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
