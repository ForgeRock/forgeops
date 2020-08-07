FROM gcr.io/forgerock-io/ig/pit1:7.0.0-784b2ba8887ffc6edc3ca5216def28a236fdd187

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
