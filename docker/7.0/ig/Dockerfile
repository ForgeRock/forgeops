FROM gcr.io/forgerock-io/ig/pit1:7.0.0-e909e4fe4441da89c1ef963660a64845980c11ae

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
