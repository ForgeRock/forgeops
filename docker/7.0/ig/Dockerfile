FROM gcr.io/forgerock-io/ig/pit1:7.0.0-e80619aef3e40facc26e0b693e07f2133ab78551

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
