FROM gcr.io/forgerock-io/ig/pit1:7.0.0-32786c476e18742473bba3e7e8e884c7f0d5a558

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
