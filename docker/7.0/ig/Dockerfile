FROM gcr.io/forgerock-io/ig/pit1:7.1.0-c68ed3fbb92ae2db4d06f12b7cc479a54e861a07

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
