FROM gcr.io/forgerock-io/ig-standalone:7.0.0-ec3af9c689f522fd6801d97f9b34820e0538780c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
