FROM gcr.io/forgerock-io/ig:7.1.0-6e368b3e4e778041f2496df356d9e13aead986a8

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
