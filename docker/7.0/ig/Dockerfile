FROM gcr.io/forgerock-io/ig:7.1.0-2020-16-e979c13c00591adeb11a27089f8ef267b9264da5

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
