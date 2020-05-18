FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-fdf4089d68251db8194c651620581056ee930e0b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
