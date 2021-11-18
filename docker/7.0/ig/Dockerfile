FROM gcr.io/forgerock-io/ig/pit1:7.1.2-2d866dc970f514dabf001d3394fdf3ded3e92028

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
