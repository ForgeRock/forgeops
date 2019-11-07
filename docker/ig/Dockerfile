FROM gcr.io/forgerock-io/ig/pit1:7.0.0-247d481a54d49c72f1bbde0ff7b30310526b2307

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
