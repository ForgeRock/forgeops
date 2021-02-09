FROM gcr.io/forgerock-io/ig/pit1:7.1.0-c29f624e94dcdf00f3db790133f443294fec67c7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
