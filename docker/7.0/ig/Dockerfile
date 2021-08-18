FROM gcr.io/forgerock-io/ig/pit1:7.2.0-2021-6-3b94ee042ed2d065fc0eda5b50cb88e2307060c5

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
