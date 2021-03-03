FROM gcr.io/forgerock-io/ig/pit1:7.1.0-2021-1-d69af231acf5656a96f4d7b2cf166c8d38a76b03

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
