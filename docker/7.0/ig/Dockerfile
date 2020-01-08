FROM gcr.io/forgerock-io/ig/pit1:7.0.0-d45578b0359e14ae1ba08f31c453b721a4e5869b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
