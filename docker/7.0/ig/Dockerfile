FROM gcr.io/forgerock-io/ig/pit1:7.1.0-f3ce6b958059baf9bdd395b974d8f076f599abac

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
