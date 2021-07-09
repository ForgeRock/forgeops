FROM gcr.io/forgerock-io/ig/pit1:7.1.0-2021-3-cf36926530815df51b5af0a8c8d684a9adda575c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
