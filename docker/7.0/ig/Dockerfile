FROM gcr.io/forgerock-io/ig/pit1:7.0.0-922c693c644dff1b98b35ff282262f9faae9f17f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
