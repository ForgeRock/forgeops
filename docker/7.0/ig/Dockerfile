FROM gcr.io/forgerock-io/ig/pit1:7.1.3-4e141874c2ed385370505d532676f1448782d34e

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
