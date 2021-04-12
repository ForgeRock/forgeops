FROM gcr.io/forgerock-io/ig/pit1:7.1.0-f58b3bbde0615256b363e15b9c7ee28676714d9e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
