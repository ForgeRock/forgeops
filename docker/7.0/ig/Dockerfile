FROM gcr.io/forgerock-io/ig/pit1:7.1.0-945913b0747666b159674746d0ecfb7223da020f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
