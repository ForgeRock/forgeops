FROM gcr.io/forgerock-io/ig/pit1:7.1.0-65dec9c96c613cc05fb368282cc83247e9383f4b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
