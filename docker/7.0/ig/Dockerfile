FROM gcr.io/forgerock-io/ig/pit1:7.1.0-f529c845c9e1c8c8439a0aba9a9298957526de6f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
