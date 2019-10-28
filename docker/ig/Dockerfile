FROM gcr.io/forgerock-io/ig/pit1:7.0.0-e63c0df57d9d8573ca9e3a9013a4507126b7d609

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
