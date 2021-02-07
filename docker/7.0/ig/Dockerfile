FROM gcr.io/forgerock-io/ig/pit1:7.1.0-dd6ade21131c4bd9cdf3cd8b93329980b1839b7d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
