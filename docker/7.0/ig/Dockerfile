FROM gcr.io/forgerock-io/ig-standalone:7.0.0-c51a93199bc9bf8bcacc10be062b27dea67d2238

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
