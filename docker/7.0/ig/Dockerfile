FROM gcr.io/forgerock-io/ig/pit1:7.1.0-f6d02330fee3723dce4101d404ec6b8a7a62065c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
