FROM gcr.io/forgerock-io/ig/pit1:7.2.0-2021-6-e2b67ca285d1338d4697fbc4228145301f1c45f7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
