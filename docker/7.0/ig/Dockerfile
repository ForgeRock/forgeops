FROM gcr.io/forgerock-io/ig/pit1:7.0.0-6aa036c91d27f44a7a481056dacd06213c69033e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
