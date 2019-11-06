FROM gcr.io/forgerock-io/ig/pit1:7.0.0-f1e103654c1084e04f4d0ac215a931d8099473c6

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
