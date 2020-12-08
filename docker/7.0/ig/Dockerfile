FROM gcr.io/forgerock-io/ig/pit1:7.1.0-0c6b6daa6b90b1d6f156bf4e53c7ec261c793a7f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
