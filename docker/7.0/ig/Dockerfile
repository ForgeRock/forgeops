FROM gcr.io/forgerock-io/ig/pit1:7.0.0-474b753dec1ad5ea7a6a391ca4b7a0d4222cc162

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
