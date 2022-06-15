FROM gcr.io/forgerock-io/ig/pit1:7.1.3-16bcd2301b6a8af32ac68c187beba9c18a0e12dd

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
