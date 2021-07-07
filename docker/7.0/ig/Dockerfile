FROM gcr.io/forgerock-io/ig/pit1:7.1.0-2021-4-d962b0b272124b1ffd835ee47c88af0fc4acdaf8

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
