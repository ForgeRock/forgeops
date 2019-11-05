FROM gcr.io/forgerock-io/ig:7.0.0-7d4542d13b722f704e678dd014fe1640d1791b54

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
