FROM gcr.io/forgerock-io/ig:7.2.0-2021-5-8ba62224fdf31d2e2ace354268cb9f34e8d184c9

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
