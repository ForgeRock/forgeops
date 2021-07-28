FROM gcr.io/forgerock-io/ig/pit1:7.1.1-841a62bc2e79e3ada23d13d1281f4731850d7ad3

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
