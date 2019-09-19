FROM gcr.io/forgerock-io/ig/pit1:7.0.0-8781929005648431b5c29e6305e7f2966810cc2b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig