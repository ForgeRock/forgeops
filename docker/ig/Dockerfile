FROM gcr.io/forgerock-io/ig/pit1:7.0.0-7354e2a77342fcd5f356412e389acc6f0a149a10

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
