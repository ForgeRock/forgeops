FROM gcr.io/forgerock-io/ig/pit1:7.0.0-de38c310eb037f74aa611649be66568166aae922

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
