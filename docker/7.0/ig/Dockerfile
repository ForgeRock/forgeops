FROM gcr.io/forgerock-io/ig/pit1:7.0.0-33379138f00f81a3cfbd554db86ed4c4f1a3a343

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
