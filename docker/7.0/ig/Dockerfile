FROM gcr.io/forgerock-io/ig/pit1:7.1.0-1b2a325510c4666531fe2222623220d9dc583d70

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
