FROM gcr.io/forgerock-io/ig/pit1:7.1.0-fdd1de4f5069f966f0139a6614824ca406df8bc7

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
