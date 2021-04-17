FROM gcr.io/forgerock-io/ig:7.1.0-25e2affb2575586bff57f6fd717f55a401584e17

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
