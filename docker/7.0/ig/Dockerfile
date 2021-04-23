FROM gcr.io/forgerock-io/ig/pit1:7.1.0-23cf465cd323590b588a6fdc0f7c6f80fd6f14bc

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
