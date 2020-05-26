FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-613b5a10181b846b50f06e3ca84c1bb1e4c285d5

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
