FROM gcr.io/forgerock-io/ig/pit1:7.1.0-a863b07dd8d80a96dade9f7dfa0ccb0395830b53

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
