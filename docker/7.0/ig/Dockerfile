FROM gcr.io/forgerock-io/ig:7.1.0-c229ca625b16b6d0fe6f02dfaf35b0b9f337d81b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
