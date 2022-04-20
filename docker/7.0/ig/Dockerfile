FROM gcr.io/forgerock-io/ig/pit1:7.1.3-0b7bfd62751844bcda9cef8062125b084015eb86

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
