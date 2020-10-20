FROM gcr.io/forgerock-io/ig/pit1:7.1.0-ef9775237d327ac248e4ce68be255cf86f5d56f1

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
