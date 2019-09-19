FROM gcr.io/forgerock-io/ig/pit1:7.0.0-b26c30a8ce50b1ed95b5819dabf8466e36daf9c2

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig