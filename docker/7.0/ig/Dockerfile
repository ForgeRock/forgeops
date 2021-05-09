FROM gcr.io/forgerock-io/ig:7.1.0-ead5e7822727b9a35536854a3c404270120fb2d7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
