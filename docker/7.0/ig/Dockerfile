FROM gcr.io/forgerock-io/ig/pit1:7.1.1-03c378ae79f020bc7752cd5151ea5961821bf4ad

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
