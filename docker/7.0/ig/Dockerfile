FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-0b786292c96643bf4b13fcfbae074291883bb895

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
