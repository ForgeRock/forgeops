FROM gcr.io/forgerock-io/ig/pit1:7.1.0-e99802384955a1e7d3196be68a71bb5aa4ef6a00

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
