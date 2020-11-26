FROM gcr.io/forgerock-io/ig/pit1:7.1.0-f59d03f970a6b238ca8bdc185ebee5a29e4b128a

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
