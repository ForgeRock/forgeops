FROM gcr.io/forgerock-io/ig/pit1:7.2.0-dc140b67b0e73e5c68aa939c3751f249e0e0def3

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
