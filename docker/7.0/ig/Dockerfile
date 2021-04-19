FROM gcr.io/forgerock-io/ig/pit1:7.2.0-c09e38ab5289aed5b9377a93ef05ce27717dd057

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
