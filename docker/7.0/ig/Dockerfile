FROM gcr.io/forgerock-io/ig/pit1:7.1.2-b3aedd940e55075b6afbd0b4b86801030f6a0691

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
