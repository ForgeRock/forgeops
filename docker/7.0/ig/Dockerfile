FROM gcr.io/forgerock-io/ig/pit1:7.0.0-6ce7645297ba572302151e2b0a8e9e1c850c3e62

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
