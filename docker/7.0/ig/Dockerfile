FROM gcr.io/forgerock-io/ig/pit1:7.0.0-35a0f5a45e5e8e2be9e705aa086fb7d42522fe2f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
