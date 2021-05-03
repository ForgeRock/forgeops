FROM gcr.io/forgerock-io/ig/pit1:7.1.0-4bdeffb62a813d82b4b85c5be2f16043caeedcd7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
