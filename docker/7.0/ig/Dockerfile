FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-8534c1e32fe86c5a21a28f6569bc60bca50bdb5e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
