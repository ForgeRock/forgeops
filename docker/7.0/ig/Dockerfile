FROM gcr.io/forgerock-io/ig:7.0.0-0b545749d058c62aa9e7acf9e8e1aa97049a6e04

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
