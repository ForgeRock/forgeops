FROM gcr.io/forgerock-io/ig/pit1:7.1.0-5f21914b97ba47dbdb288b6493f4547bae605edf

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
