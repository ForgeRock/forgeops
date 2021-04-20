FROM gcr.io/forgerock-io/ig/pit1:7.1.0-979f6848c478f3fc71aeb32dd0f31f0054e51e29

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
