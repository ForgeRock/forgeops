FROM gcr.io/forgerock-io/ig/pit1:7.1.2-1f5b283d807cdcdc2def0d072b91a8581a44ca50

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
