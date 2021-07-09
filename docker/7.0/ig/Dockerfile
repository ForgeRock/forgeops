FROM gcr.io/forgerock-io/ig/pit1:7.2.0-2021-8-5e68c604d19e763144da649d3dd17d17410f2331

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
