FROM gcr.io/forgerock-io/ig/pit1:7.0.0-b713a8ce1784b2bfd326beff0f1d60e8ae0913d4

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
