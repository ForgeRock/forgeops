FROM gcr.io/forgerock-io/ig:7.0.0-d4391a0b715fe6da0b1c06553b397a753b4629b1

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
