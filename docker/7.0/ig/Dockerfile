FROM gcr.io/forgerock-io/ig/pit1:7.1.2-cd802210f1aeb14b07675c28964286a454888fc4

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
