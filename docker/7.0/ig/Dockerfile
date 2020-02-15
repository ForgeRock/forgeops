FROM gcr.io/forgerock-io/ig/pit1:7.0.0-c79e569801511f8200f625a953e9819f076cd2c2

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
