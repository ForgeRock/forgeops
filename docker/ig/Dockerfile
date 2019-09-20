FROM gcr.io/forgerock-io/ig/pit1:7.0.0-8df18ec281fe729aee0eb88b3b10ff7f8577d2dc

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig