FROM gcr.io/forgerock-io/ig/pit1:7.1.0-2020-15-62ea581121ca25ccabc3c04bf1df77a2102c10d5

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
