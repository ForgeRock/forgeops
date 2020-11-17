FROM gcr.io/forgerock-io/ig/pit1:7.1.0-2020-14-eb843e98a4e7a8197040c06fdc78d98e4b892f26

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
