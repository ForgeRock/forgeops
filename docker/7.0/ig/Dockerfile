FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-4d4a78cbe52c038690f1d5dc9cad30147167faf3

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
