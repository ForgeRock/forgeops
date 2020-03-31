FROM gcr.io/forgerock-io/ig:7.0.0-aee7a3c380d809b83afca8ef4335b0977bb38a6c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
