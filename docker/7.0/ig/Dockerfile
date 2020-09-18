FROM gcr.io/forgerock-io/ig:7.1.0-b9e50485a656ce954a0d213914b24be2d422a22a

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
