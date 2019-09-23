FROM gcr.io/forgerock-io/ig/pit1:7.0.0-d21defd3a39c96c6fa5eb447722e20b9757fc0d0

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig