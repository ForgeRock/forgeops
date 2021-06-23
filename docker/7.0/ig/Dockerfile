FROM gcr.io/forgerock-io/ig/pit1:7.2.0-0f39732454652c438f6092d4246617e5074ec4ae

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
