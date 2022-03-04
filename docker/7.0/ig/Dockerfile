FROM gcr.io/forgerock-io/ig/pit1:7.1.2-c748cada37ebca3a674700623713b376edc9faef

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
