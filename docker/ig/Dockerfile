FROM gcr.io/forgerock-io/ig/pit1:7.0.0-661aab42a93747e2ef8bcc4d9244760972b1550c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
