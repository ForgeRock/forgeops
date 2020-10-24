FROM gcr.io/forgerock-io/ig/pit1:7.1.0-f84cbf4014d86cdc528fba79a77ecae3fdbd62e8

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
