FROM gcr.io/forgerock-io/ig/pit1:7.0.0-d286bf6930d4b7d06c62ac0fe17ac0442a6e2110

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
#COPY --chown=forgerock ./basic /var/ig

COPY --chown=forgerock ./benchmark /var/ig