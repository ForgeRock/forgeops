FROM gcr.io/forgerock-io/ig/pit1:7.1.0-f58db97abf6c1a169bfa68f52830b4478ab1ab02

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
