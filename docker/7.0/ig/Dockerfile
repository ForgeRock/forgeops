FROM gcr.io/forgerock-io/ig/pit1:7.0.0-43b81e9721c7a5613dd6f7544e87e95833630e26

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
