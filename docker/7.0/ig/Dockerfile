FROM gcr.io/forgerock-io/ig/pit1:7.1.0-e8d070ac3ae014adb229ad0fd8b48944b326d969

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
