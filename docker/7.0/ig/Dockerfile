FROM gcr.io/forgerock-io/ig/pit1:7.2.0-5055130ca93cb387d08369a91af96d262b7a96d7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
