FROM gcr.io/forgerock-io/ig/pit1:7.1.0-2021-3-f8b116dd87f6d4db29fbf9d5e4e68a36cd28488a

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
