FROM gcr.io/forgerock-io/ig/pit1:7.0.0-0f105d5b29a5ddcbb51effab13afa2810b23601c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
