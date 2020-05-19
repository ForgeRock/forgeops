FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-c1488c984783d193247d9c458f33102a0d69d785

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
