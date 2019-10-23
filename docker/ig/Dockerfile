FROM gcr.io/forgerock-io/ig/pit1:7.0.0-94a14fbd0bce48c60edd6b1fe10d5f22ed94692d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock ./basic /var/ig

#COPY --chown=forgerock ./benchmark /var/ig
