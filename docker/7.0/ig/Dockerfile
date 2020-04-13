FROM gcr.io/forgerock-io/ig-standalone:7.0.0-469b9febdeceb14ed43598a7ea5f15b1ee54371e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
