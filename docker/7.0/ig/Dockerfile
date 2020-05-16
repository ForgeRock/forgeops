FROM gcr.io/forgerock-io/ig-standalone:7.0.0-da537f34aeb9cdd2d9a28261e0ca3e34ace2132b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
