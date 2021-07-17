FROM gcr.io/forgerock-io/ig:7.2.0-2021-6-62143866fde227da9dd3a17bed2f7add8ce28a80

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
