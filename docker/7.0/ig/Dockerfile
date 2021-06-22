FROM gcr.io/forgerock-io/ig/pit1:7.2.0-7de45520ce95f916767ec4fa812a9594fb4e67ff

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
