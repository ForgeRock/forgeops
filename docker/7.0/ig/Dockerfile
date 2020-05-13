FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-067a2097f2f9bbad070f4ed465093764fbdc494e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
