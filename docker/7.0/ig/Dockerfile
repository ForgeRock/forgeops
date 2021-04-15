FROM gcr.io/forgerock-io/ig/pit1:7.1.0-8ea0d452d499945cebdbea243c34dcf8a11df576

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
