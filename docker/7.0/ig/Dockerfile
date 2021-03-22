FROM gcr.io/forgerock-io/ig/pit1:7.1.0-c2700cba77b1b361699ad8354de7d57a2b060a84

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
