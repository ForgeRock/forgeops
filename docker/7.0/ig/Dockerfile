FROM gcr.io/forgerock-io/ig/pit1:7.0.0-b5b8455473a1303cde07a311353e5137121e5d3d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
