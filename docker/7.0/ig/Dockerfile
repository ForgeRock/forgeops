FROM gcr.io/forgerock-io/ig/pit1:7.1.0-557cf112eb5c9c3d477fd4ef46080f81619a7bdb

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
