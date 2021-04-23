FROM gcr.io/forgerock-io/ig/pit1:7.2.0-58b56b6472a20031797d89aa4ee208edfa3dacde

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
