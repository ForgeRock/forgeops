FROM gcr.io/forgerock-io/ig:7.1.0-8005e6874e3f9240a13eb15586ae3cd5d5458637

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
