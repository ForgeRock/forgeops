FROM gcr.io/forgerock-io/ig/pit1:7.1.0-ed9da776e7183ca37e0483a379bf9e272add3075

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
