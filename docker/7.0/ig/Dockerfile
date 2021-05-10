FROM gcr.io/forgerock-io/ig/pit1:7.1.0-d73b6d45d598508561d3bb4f4a7ff0c56a84f255

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
