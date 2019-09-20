FROM gcr.io/forgerock-io/ig/pit1:7.0.0-9659d14ab7784ba52c36e691d3acfb37f2f2a7d2

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig