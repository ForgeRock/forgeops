FROM gcr.io/forgerock-io/ig/pit1:7.1.2-f3b2ed997527b99f4acee0ce3bea7b4871a07a58

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
