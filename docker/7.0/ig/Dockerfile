FROM gcr.io/forgerock-io/ig/pit1:7.1.0-46fc43064fbe01057d8a93c8a808f5321915cea7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
