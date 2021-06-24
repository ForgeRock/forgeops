FROM gcr.io/forgerock-io/ig/pit1:7.1.1-da751aa9bb6f2b98ed477163ab498c5d36716c9c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
