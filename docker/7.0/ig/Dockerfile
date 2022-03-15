FROM gcr.io/forgerock-io/ig/pit1:7.1.2-a2def81996434d62ef49a012b8dcaecb2588397e

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
