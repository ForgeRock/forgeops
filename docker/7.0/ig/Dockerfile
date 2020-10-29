FROM gcr.io/forgerock-io/ig/pit1:7.1.0-6936176ee62321cbd1c242d7f04128e080925d48

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
