FROM gcr.io/forgerock-io/ig/pit1:7.0.0-003910c56ce2b4232043660cc9e13eeefaeca39e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
