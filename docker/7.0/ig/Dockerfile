FROM gcr.io/forgerock-io/ig/pit1:7.0.0-b120df3e07ee0325d1c5406a6fb0bea698b15a48

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
