FROM gcr.io/forgerock-io/ig/pit1:7.0.0-f4d6e158d7bb80eff768d4355ccd83bb568cd44f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig