FROM gcr.io/forgerock-io/ig/pit1:7.1.0-43c94805bd349975b072ae4f2140572da6044509

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
