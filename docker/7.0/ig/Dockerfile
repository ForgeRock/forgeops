FROM gcr.io/forgerock-io/ig:7.1.0-8d84fb61fae5f6165f247f86e7087648baf89596

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
