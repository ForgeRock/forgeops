FROM gcr.io/forgerock-io/ig/pit1:7.0.0-f0d69c8e7bc7135869128b6a2f9a0c5dc3465f81

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig