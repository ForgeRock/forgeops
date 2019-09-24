FROM gcr.io/forgerock-io/ig/pit1:7.0.0-aed085e1b86848802951f940e81a8da479429f59

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig