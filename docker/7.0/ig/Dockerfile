FROM gcr.io/forgerock-io/ig/pit1:7.0.0-231477340878bc7ca9179fa61a84ad2f972e0e36

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
