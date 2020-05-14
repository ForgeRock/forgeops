FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-669c48b4fee5c48b059d05cd5144e0d51e5fc799

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
