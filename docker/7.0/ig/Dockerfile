FROM gcr.io/forgerock-io/ig/pit1:7.1.0-2021-3-e20e2e3e855e5e462b5540694b008acf4033acbb

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
