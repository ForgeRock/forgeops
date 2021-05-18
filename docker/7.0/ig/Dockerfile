FROM gcr.io/forgerock-io/ig/pit1:7.2.0-3d88e59bc5778a0a51be9f2b073b452ae8a5f46d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
