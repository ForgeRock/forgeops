FROM gcr.io/forgerock-io/ig/pit1:7.2.0-e86bd520240c3ea69105b47ba702762b45076c5d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
