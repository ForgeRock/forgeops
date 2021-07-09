FROM gcr.io/forgerock-io/ig/pit1:7.1.1-f4199f152d3e423a94f2b8f88b147b727f999c7b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
