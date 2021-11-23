FROM gcr.io/forgerock-io/ig/pit1:7.1.2-d1b1aca88698a64ec8d29f4e7a1bcf3e8db4497f

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
