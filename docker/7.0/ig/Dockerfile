FROM gcr.io/forgerock-io/ig/pit1:7.1.0-IDCLOUD-7b07f1e8ce1b011a0ab6df632fd7eb87728b7d63

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
