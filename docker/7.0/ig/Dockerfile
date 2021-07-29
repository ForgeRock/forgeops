FROM gcr.io/forgerock-io/ig/pit1:7.1.1-24b12cb1c2465a6e3d938e12213ad091f7e1790f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
