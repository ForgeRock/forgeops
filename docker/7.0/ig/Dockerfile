FROM gcr.io/forgerock-io/ig:7.0.0-da5261166e01ae7ddbea750b63da80484cb67610

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
