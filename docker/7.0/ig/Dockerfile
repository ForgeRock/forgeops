FROM gcr.io/forgerock-io/ig/pit1:7.1.0-3533eb9f420e66c74ae0b4d2075dddb1118e847a

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
