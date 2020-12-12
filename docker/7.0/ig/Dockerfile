FROM gcr.io/forgerock-io/ig/pit1:7.1.0-3ba91271c00e4bf21915b99fad9a16363bd5d905

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
