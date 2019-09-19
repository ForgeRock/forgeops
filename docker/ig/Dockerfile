FROM gcr.io/forgerock-io/ig/pit1:7.0.0-d7ed5842693717886cdcef052b424e0c2fb748ce

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig