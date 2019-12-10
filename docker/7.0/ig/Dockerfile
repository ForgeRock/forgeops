FROM gcr.io/forgerock-io/ig/pit1:7.0.0-87de0b5f16f7c51ff29add4b7452944f4b003443

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
