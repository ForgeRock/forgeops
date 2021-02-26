FROM gcr.io/forgerock-io/ig:7.1.0-e8c9a89158dc2cc95d056bfcd1d3d9514cbd26c3

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
