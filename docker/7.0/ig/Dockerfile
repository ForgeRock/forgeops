FROM gcr.io/forgerock-io/ig/pit1:7.1.0-54462d3257a6b0a1ded9585f55dd06098504a170

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
