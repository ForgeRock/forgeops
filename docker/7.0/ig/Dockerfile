FROM gcr.io/forgerock-io/ig/pit1:7.2.0-3b33bdfe03d706f08272ddf8d4ab154e36ddbb4d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
