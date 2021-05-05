FROM gcr.io/forgerock-io/ig/pit1:7.2.0-9d02b34b84494da04658d3bf25d4ad34ac7cab52

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
