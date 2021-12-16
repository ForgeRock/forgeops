FROM gcr.io/forgerock-io/ig/pit1:7.1.2-69d2140af7d563c185bec6ec161d2e2d10ea9cc5

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
