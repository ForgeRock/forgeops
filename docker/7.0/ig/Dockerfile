FROM gcr.io/forgerock-io/ig/pit1:7.2.0-ad573e7b3e258d612bcb792c60dd0c515de6906f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
