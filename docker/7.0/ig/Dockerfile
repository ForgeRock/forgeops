FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-5d3905686f47ad24e5b4acbbba24734d34a27b0b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
