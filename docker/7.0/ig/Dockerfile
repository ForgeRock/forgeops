FROM gcr.io/forgerock-io/ig/pit1:7.0.0-59c17ec5bfe91acedc84b2ad90f91eeab236fecd

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
