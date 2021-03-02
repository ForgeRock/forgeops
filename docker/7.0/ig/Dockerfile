FROM gcr.io/forgerock-io/ig/pit1:7.1.0-6d2833cad979e70085bdfb6ac0a37050145db88f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
