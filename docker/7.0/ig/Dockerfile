FROM gcr.io/forgerock-io/ig/pit1:7.1.0-7910b2a5062c28af196e07cb1c9c907d2788a01c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
