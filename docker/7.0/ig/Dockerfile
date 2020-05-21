FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-d68d3bde378e1370a696b075755907ab64e2463e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
