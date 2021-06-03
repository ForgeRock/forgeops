FROM gcr.io/forgerock-io/ig/pit1:7.2.0-e54317b0087ec0f63b2df1ff488b54edabc83e50

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
