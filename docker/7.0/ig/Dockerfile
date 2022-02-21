FROM gcr.io/forgerock-io/ig/pit1:7.1.2-ea73031d135b94810b141b4a24264c9e88f3f1a5

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
