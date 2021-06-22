FROM gcr.io/forgerock-io/ig/pit1:7.2.0-9b905f9ecb07dcb81c965ae74ca843fcc7af359c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
