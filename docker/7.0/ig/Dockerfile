FROM gcr.io/forgerock-io/ig:7.1.0-f67a920eeacf36204a54b5b1adf83f511958ef1f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
