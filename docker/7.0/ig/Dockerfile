FROM gcr.io/forgerock-io/ig/pit1:7.1.0-77f75da5735143fc0af7c20c1e65946556d5089c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
