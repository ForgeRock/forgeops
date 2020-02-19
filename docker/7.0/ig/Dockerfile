FROM gcr.io/forgerock-io/ig/pit1:7.0.0-a4891f0da3a55dbb3ab4c53b3bdf53200139375c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
