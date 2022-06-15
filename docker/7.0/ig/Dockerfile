FROM gcr.io/forgerock-io/ig/pit1:7.1.3-b3344c63f48888e013da593c0f0ec6f17d1ac77f

COPY debian-buster-sources.list /etc/apt/sources.list

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
