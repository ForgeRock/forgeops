FROM gcr.io/forgerock-io/ig/pit1:7.0.0-14b090a1213bef2c73b71ebae2176349b35539e0

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
