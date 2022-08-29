FROM gcr.io/forgerock-io/ig/pit1:7.1.3-4d61d57051c5d0a2a6d78448b83361fe91ef1738

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
