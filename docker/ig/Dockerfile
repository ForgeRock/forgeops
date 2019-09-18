FROM gcr.io/forgerock-io/ig/pit1:7.0.0-4d0ebbc1c340c17e549df706e4f36937e1b3e8dd

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig