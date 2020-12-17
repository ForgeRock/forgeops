FROM gcr.io/forgerock-io/ig/pit1:7.1.0-81a94bcc71eddc582376f695d9d0cc297cbf7115

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
