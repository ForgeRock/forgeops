FROM gcr.io/forgerock-io/ig/pit1:7.0.0-f1480522e89fcfc8d25a0d4eb84de7230582ef3b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock ./basic /var/ig

#COPY --chown=forgerock ./benchmark /var/ig
