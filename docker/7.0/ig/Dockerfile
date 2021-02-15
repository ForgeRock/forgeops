FROM gcr.io/forgerock-io/ig/pit1:7.1.0-9d314a5d2c909e4266e588bf14ea227f4d82fb65

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
