FROM gcr.io/forgerock-io/ig/pit1:7.1.0-50ff00b440fee3eba296a66e454b5c6d972fafb7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
