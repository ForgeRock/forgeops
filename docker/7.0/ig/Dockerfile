FROM gcr.io/forgerock-io/ig/pit1:7.1.0-f9ca743ece2bdb6d8880aefe49dad86f3e33af3f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
