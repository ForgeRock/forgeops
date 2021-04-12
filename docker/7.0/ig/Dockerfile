FROM gcr.io/forgerock-io/ig/pit1:7.1.0-f578b16f67e10e73d7eeb3f23c9415ab02e1c1e4

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
