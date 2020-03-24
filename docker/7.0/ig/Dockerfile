FROM gcr.io/forgerock-io/ig/pit1:7.0.0-59e95937b521091f795fb4787e7d19832dd64870

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
