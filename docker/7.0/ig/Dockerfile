FROM gcr.io/forgerock-io/ig/pit1:7.1.0-f5421b125844df4663e1464de02a63c64df10812

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
