FROM gcr.io/forgerock-io/ig/pit1:7.1.2-d2c62d0da8245c3a9520c60713ed6e8313cdf402

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
