FROM gcr.io/forgerock-io/ig/pit1:7.1.1-0e4d46e40dc45f9e1e741c3275afb6c7ebc39d1d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
