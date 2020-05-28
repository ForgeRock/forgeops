FROM gcr.io/forgerock-io/ig/pit1:7.0.0-67d6c890093bbc057fb1b3dd7f1b4a1110b6ee54

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
