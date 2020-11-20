FROM gcr.io/forgerock-io/ig/pit1:7.1.0-9910ee2f6635e1e76e388b81c1abec92cb547c42

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
