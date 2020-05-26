FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-0b674edb74536f9771b840e73841a3f3c3a53a8c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
