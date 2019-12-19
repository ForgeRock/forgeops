FROM gcr.io/forgerock-io/ig/pit1:7.0.0-e8307fb09e625a275c0891f329b022485ea2cb9f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
