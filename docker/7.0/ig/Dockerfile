FROM gcr.io/forgerock-io/ig/pit1:7.1.0-bb78b67b2fcba3926e2204c34fbc04219ac494e9

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
