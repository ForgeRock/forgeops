FROM gcr.io/forgerock-io/ig/pit1:7.2.0-914a8857f8cbd0650ee546a22a0b44f33d818373

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
