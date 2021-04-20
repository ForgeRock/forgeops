FROM gcr.io/forgerock-io/ig/pit1:7.2.0-a96f551ac8e869db43f91aab6bb733ad38b989e1

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
