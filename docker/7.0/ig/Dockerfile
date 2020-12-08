FROM gcr.io/forgerock-io/ig/pit1:7.1.0-bfa3060fdb42e3c033e280f61d74ab405af97817

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
