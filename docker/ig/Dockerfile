FROM gcr.io/forgerock-io/ig/pit1:7.0.0-d85f6116b4c8e5acaca73e1933d0e480b9d7da2d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
