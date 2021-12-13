FROM gcr.io/forgerock-io/ig/pit1:7.1.2-d64b5f4a59b0575dda3708bc4dd75bb55c00282f

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
