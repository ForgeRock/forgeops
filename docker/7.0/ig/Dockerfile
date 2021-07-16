FROM gcr.io/forgerock-io/ig:7.1.0-2021-4-b1c6a07e9f48be4f7ed8f4a87950577d41d8ad1b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
