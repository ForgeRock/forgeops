FROM gcr.io/forgerock-io/ig/pit1:7.1.2-76178677db0bbc1d9d50d3237f12ba3757aeca7f

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
