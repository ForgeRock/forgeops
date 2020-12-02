FROM gcr.io/forgerock-io/ig/pit1:7.1.0-52bfb86a55efd2c21ca476f2c8d601b081ea2d12

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
