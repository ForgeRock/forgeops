FROM gcr.io/forgerock-io/ig/pit1:7.0.0-1719e0db3b4c8d74451b9a62ea41397fc32fab6d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
