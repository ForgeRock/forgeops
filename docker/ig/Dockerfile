FROM gcr.io/forgerock-io/ig/pit1:7.0.0-b07fcd77803ee981a790997cbdecb2ab7b7adece

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock ./basic /var/ig

#COPY --chown=forgerock ./benchmark /var/ig
