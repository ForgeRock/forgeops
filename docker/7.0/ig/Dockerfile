FROM gcr.io/forgerock-io/ig:7.0.0-86614b5db10a124232f1aaae8b5863914f83205f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
