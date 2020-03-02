FROM gcr.io/forgerock-io/ig:7.0.0-a4d51290e39336cf006bb39071d8c4c5541f98c8

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
