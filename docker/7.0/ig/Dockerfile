FROM gcr.io/forgerock-io/ig:7.0.0-c52b31fd427eb0dbf3f91dfafcbbf22279a53570

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
