FROM gcr.io/forgerock-io/ig/pit1:7.0.0-ca5efdcc923fd15e72afa7be9445354393d2be40

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig