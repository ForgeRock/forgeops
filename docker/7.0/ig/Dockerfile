FROM gcr.io/forgerock-io/ig/pit1:7.1.0-df9e93053c3186a8ad6ff209e408c2bfafea1cd6

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
