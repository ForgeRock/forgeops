FROM gcr.io/forgerock-io/ig/pit1:7.2.0-86493a78295439b36997b451a14c79ef284775e2

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
