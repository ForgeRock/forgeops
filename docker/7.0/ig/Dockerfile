FROM gcr.io/forgerock-io/ig:7.0.0-9e5fb98f076b3c1d6b2da67180464c4332050792

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
