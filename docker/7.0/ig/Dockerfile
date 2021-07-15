FROM gcr.io/forgerock-io/ig/pit1:7.2.0-2021-5-66119c0090be8771d920a1388b43645aa49643a7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
