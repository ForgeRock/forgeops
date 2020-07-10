FROM gcr.io/forgerock-io/ig:7.0.0-934a943f268281df897aebf0eb46500584e54126

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
