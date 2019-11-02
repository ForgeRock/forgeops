FROM gcr.io/forgerock-io/ig:7.0.0-2525deb56deee06692f5feb12f67f75b012e782f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
