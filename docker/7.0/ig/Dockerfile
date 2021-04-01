FROM gcr.io/forgerock-io/ig/pit1:7.1.0-a698ec6327acc7be778f9bd30e6ddeb9947f8b3a

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
