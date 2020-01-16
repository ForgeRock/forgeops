FROM gcr.io/forgerock-io/ig/pit1:7.0.0-801864056dd3ce04ef4695259398ca12fec4e9ba

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
