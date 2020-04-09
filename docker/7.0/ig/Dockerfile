FROM gcr.io/forgerock-io/ig/pit1:7.0.0-4d4e7e3fba49d7725956d138df92f6b67b023dd8

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
