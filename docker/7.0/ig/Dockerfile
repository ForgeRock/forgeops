FROM gcr.io/forgerock-io/ig/pit1:7.1.1-a25d365d2ab976f3bcc108195c4e8123901b587a

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
