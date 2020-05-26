FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-425fb8db405aa3aa3ca1ee74189f68d31ea1de3f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
