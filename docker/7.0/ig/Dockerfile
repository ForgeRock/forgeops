FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-8b595c6454ccaeb4f281c4ecf7642d9a9a20c69a

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
