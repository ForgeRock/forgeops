FROM gcr.io/forgerock-io/ig/pit1:7.1.0-c2a457f3f3b5852d6c43595f9e6db585be596554

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
