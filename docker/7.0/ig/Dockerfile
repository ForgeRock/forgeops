FROM gcr.io/forgerock-io/ig/pit1:7.1.0-f54fcb723d5dc9ddbb98863c19cd19cc6b014486

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
