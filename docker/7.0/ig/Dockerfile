FROM gcr.io/forgerock-io/ig/pit1:7.2.0-1664be9df5434952e4cd2547fef3498015dc05f9

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
