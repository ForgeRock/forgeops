FROM gcr.io/forgerock-io/ig/pit1:7.1.0-b6e9f21677202dd94158c320fb01778575562b91

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
