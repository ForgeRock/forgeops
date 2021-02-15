FROM gcr.io/forgerock-io/ig/pit1:7.1.0-28350a7a333cefd722d2953ac969368b9272f0c7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
