FROM gcr.io/forgerock-io/ig/pit1:7.2.0-f012f4f4b75561f552be234cc077f993b8c430c3

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
