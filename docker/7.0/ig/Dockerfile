FROM gcr.io/forgerock-io/ig/pit1:7.2.0-72a1c2dc9fe0f40bbb64666497dedad69c52ee33

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
