FROM gcr.io/forgerock-io/ig/pit1:7.1.3-7bc718df678345fc77f7b8f4ae386889851c359f

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
