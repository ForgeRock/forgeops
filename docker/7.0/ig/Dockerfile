FROM gcr.io/forgerock-io/ig/pit1:7.1.0-4b93da1a7365d928d68a1ca3d07fbbb755b91ece

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
