FROM gcr.io/forgerock-io/ig/pit1:7.1.0-IDCLOUD-6049f951df4c5d09601433a1931a213fae4dce28

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
