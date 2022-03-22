FROM gcr.io/forgerock-io/ig/pit1:7.1.2-53f10e18783eca2e8da1d40ca06be5721bec3f55

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
