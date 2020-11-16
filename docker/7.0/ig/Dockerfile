FROM gcr.io/forgerock-io/ig:7.1.0-a178273771ac2c3946cc8b7693dbb3ca8305edd9

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
