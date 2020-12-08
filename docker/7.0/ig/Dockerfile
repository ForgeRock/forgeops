FROM gcr.io/forgerock-io/ig:7.1.0-IDCLOUD-f3be92aab1034d19eb6ac47c86518014d51865b2

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
