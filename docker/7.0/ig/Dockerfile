FROM gcr.io/forgerock-io/ig:7.0.0-b71d29fed1e665d4781d9cc9c875196980c55136

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
