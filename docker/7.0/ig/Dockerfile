FROM gcr.io/forgerock-io/ig/pit1:7.1.0-2d2a90517f4e2e621642511c77040ff0d6ec10d9

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
