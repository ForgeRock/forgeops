FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-91bb602cd3799048a245b8fe6c42acb72fc6c754

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
