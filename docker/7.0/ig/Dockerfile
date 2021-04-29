FROM gcr.io/forgerock-io/ig/pit1:7.1.0-1caa41acffd5180415ca8ab202458dc39cd71360

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
