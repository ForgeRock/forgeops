FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-112cd19a4c3d024e1970e950c32450737791fa89

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
