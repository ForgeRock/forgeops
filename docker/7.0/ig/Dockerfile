FROM gcr.io/forgerock-io/ig:7.0.0-915565bbb28194001a969ccf6d90e1eb24271f96

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
