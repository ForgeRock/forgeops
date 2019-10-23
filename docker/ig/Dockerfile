FROM gcr.io/forgerock-io/ig/pit1:7.0.0-77a3a9ee609f8545e2b0fd01fea6569e59f5aad4

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock ./basic /var/ig

#COPY --chown=forgerock ./benchmark /var/ig
