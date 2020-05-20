FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-a5e834843fa19e783e79d699bf557399ffa9b224

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
