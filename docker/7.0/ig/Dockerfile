FROM gcr.io/forgerock-io/ig:7.0.0-4d5ab57a06f183532f8ac7b57e420800931b05d3

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
