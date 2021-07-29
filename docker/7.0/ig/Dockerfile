FROM gcr.io/forgerock-io/ig/pit1:7.1.1-007cad3dc9b79421258b7700a39cf39aa2d513ae

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
