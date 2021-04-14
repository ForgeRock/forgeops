FROM gcr.io/forgerock-io/ig/pit1:7.2.0-6e0fe5a9c3fb718682c2786fb5fa9ad8ebfc710b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
