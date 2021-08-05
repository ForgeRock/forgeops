FROM gcr.io/forgerock-io/ig/pit1:7.1.1-16c615ea024d5f833205c7869cb38e3147cf8d32

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
