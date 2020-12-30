FROM gcr.io/forgerock-io/ig/pit1:7.1.0-6dd1191655aa4de3e7b47ecd24412647f5d7f21e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
