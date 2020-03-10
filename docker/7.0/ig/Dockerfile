FROM gcr.io/forgerock-io/ig/pit1:7.0.0-36d6aedf87b4a67dcbb5bfb09212fbab025c54bc

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
