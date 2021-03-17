FROM gcr.io/forgerock-io/ig/pit1:7.1.0-d0c71640dc054b60bb87a0657b3ef43384ad7302

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
