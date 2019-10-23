FROM gcr.io/forgerock-io/ig/pit1:7.0.0-f9a728f27158bf93cd195bb0b4cc33605af20559

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
