FROM gcr.io/forgerock-io/ig/pit1:7.2.0-0059382069e0776e3441995ba89040e58732db85

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
