FROM gcr.io/forgerock-io/ig/pit1:7.1.2-cfc5d4676edbb7b744252c2979e3d82e9200faa6

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
