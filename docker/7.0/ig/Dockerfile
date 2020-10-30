FROM gcr.io/forgerock-io/ig/pit1:7.1.0-b40a4e2b7b79dc7d3cdb0ae4d9e175eda7ddab1b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
