FROM gcr.io/forgerock-io/ig/pit1:7.0.0-af2ee9adc5de83bd90c7c11f8b9f1f4a96c5a890

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
