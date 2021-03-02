FROM gcr.io/forgerock-io/ig/pit1:7.1.0-bcd8efb738c6ce108c99aa42d4f1419b331c0eba

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
