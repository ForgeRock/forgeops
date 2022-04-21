FROM gcr.io/forgerock-io/ig/pit1:7.1.3-f74d9dacca4a9c1c069ed782371a41dc64621415

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
