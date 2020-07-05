FROM gcr.io/forgerock-io/ig:7.0.0-4d558d06eed778ffe46fe8c1c9908762f113538e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
