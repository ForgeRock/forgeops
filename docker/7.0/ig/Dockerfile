FROM gcr.io/forgerock-io/ig/pit1:7.2.0-53839c9ecd70d0e8eda92403bc07de094b539646

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
