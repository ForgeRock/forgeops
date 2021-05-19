FROM gcr.io/forgerock-io/ig/pit1:7.2.0-5bfba0248dcd2009310a54ab896e3dd70cbb4f8d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
