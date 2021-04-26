FROM gcr.io/forgerock-io/ig/pit1:7.2.0-a13ba66b965ed8f81abf037c2863395f3a5dc9d2

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
