FROM gcr.io/forgerock-io/ig/pit1:7.0.0-7ecf6c5fcadff2f305d57bbfc5a4795259057691

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
