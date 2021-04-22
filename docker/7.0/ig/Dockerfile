FROM gcr.io/forgerock-io/ig/pit1:7.2.0-02232c23e97a42258072f81033657a8c45ae02e6

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
