FROM gcr.io/forgerock-io/ig/pit1:7.1.0-76780fafce1ff210a15922223e9a49dc121b48a7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
