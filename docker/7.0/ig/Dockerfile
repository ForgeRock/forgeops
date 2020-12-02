FROM gcr.io/forgerock-io/ig/pit1:7.1.0-509737c11bee1776753ad53bc2ce97b03364eaf6

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
