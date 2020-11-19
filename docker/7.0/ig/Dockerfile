FROM gcr.io/forgerock-io/ig:7.1.0-8ebe9ed3b7505cf60e169bd7e6f63baa42531a73

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
