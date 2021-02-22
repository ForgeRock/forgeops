FROM gcr.io/forgerock-io/ig/pit1:7.1.0-9447337e15e2f02a702931e3988ff2c0423f0ccc

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
