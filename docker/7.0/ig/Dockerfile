FROM gcr.io/forgerock-io/ig/pit1:7.1.2-30844eebfe48fe99099fa0cecdb0681f8f75419f

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
