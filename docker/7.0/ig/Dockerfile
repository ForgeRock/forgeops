FROM gcr.io/forgerock-io/ig/pit1:7.1.0-fee8334e0c0160028cdf92ea5d520fba6a53030a

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
