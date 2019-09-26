FROM gcr.io/forgerock-io/ig:7.0.0-3f02abb29f49b919dceecc60ed07385702d2dc5f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig