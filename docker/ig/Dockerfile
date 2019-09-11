FROM gcr.io/forgerock-io/ig/pit1:7.0.0-d21703c8e067e90016ec8ddf770e37a7894c9e6d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig