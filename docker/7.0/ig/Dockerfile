FROM gcr.io/forgerock-io/ig/pit1:7.2.0-caa0d122db26aa8a48b2302ae8532010395ab8e8

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
