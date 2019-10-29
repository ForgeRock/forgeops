FROM gcr.io/forgerock-io/ig/pit1:7.0.0-2568c23d0d7eb80ea6c6ef882d3b74dc3090d73d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
