FROM gcr.io/forgerock-io/ig:7.1.0-2020-17-328454b160d964da3d58c23da04dae43dbca95f7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
