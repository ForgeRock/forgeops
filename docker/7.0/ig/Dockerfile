FROM gcr.io/forgerock-io/ig/pit1:7.2.0-b31eaeb50bab296f3efbe9988395332ba66db3b1

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
