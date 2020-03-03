FROM gcr.io/forgerock-io/ig/pit1:7.0.0-5e9a617f2d32d8fd6f2fe2ad29cd539887a1254f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
