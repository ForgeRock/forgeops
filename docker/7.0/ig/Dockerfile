FROM gcr.io/forgerock-io/ig:7.0.0-23ab3d1833acb2f1e4292ea5b90d20e1c1e0f006

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
