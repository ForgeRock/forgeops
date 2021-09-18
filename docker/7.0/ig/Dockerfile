FROM gcr.io/forgerock-io/ig/pit1:7.1.1-f19984b2f9ba6165513ffe05e05af43476d4b2e5

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
