FROM gcr.io/forgerock-io/ig/pit1:7.1.0-cb65e0c7cd7eece712033957a9c31233c254f126

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
