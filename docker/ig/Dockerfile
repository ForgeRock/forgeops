FROM gcr.io/forgerock-io/ig/pit1:7.0.0-d3262519e3deabca4f3f5271e636843b707a0871

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig