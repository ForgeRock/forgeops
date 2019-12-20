FROM gcr.io/forgerock-io/ig/pit1:7.0.0-7c421b32243d41a2f03da6b0c0177219981f1690

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
