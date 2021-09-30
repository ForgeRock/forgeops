FROM gcr.io/forgerock-io/ig/pit1:7.1.2-cb8938174c87e106c8434f3c79dc836155a579c8

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
