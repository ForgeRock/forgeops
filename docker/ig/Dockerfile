FROM gcr.io/forgerock-io/ig/pit1:7.0.0-09bcbdaf0b37061a9b22dbceb9874b1502eee970

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig