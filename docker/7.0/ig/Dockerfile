FROM gcr.io/forgerock-io/ig/pit1:7.0.0-3f02791cf6273b3ce3e9e4866f3f9bdf7a2e483e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
