FROM gcr.io/forgerock-io/ig/pit1:7.1.0-75d93887e734e5a1ba59c3e3164d8ca92b806c05

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
