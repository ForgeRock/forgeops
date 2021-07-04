FROM gcr.io/forgerock-io/ig/pit1:7.2.0-5d4772ec22feb229ffa64b0b99fcd265f3c4a6fb

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
