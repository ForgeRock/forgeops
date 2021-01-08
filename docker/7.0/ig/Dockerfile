FROM gcr.io/forgerock-io/ig/pit1:7.1.0-a15dbd2e4c0a28456cc3e66fc519857043a8eb76

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
