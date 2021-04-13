FROM gcr.io/forgerock-io/ig/pit1:7.2.0-019e17e0a55d685569d6fe58d001e77120615c44

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
