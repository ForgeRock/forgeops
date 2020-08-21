FROM gcr.io/forgerock-io/ig:7.1.0-1f4fc3d83c81616a7d85aadf87220dff58610bfa

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
