FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-51a4992b6435c4ca91915b072e248e47ac72cfbb

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
