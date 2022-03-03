FROM gcr.io/forgerock-io/ig/pit1:7.1.2-f472d9eaba09ce370c66a941c7eb4290d8ca31bc

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
