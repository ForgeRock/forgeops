FROM gcr.io/forgerock-io/ig/pit1:7.1.0-59063ae220fae498a04fb1740d95cc8201e50b2e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
