FROM gcr.io/forgerock-io/ig/pit1:7.1.1-eb9129fef87a36dc9b626f1d2da7c34cb3cd2992

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
