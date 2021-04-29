FROM gcr.io/forgerock-io/ig:7.2.0-053bc4586af66090c8f16a5a9494da98352838ba

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
