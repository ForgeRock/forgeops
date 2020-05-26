FROM gcr.io/forgerock-io/ig-standalone:7.0.0-0a8d76ed7f3ce06e4cefdea0aa7dcc45e75bdd0c

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
