FROM gcr.io/forgerock-io/ig/pit1:7.2.0-d77e965e5cf57a2dd3ada800196b54dfa3a68a9f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
