FROM gcr.io/forgerock-io/ig/pit1:7.1.0-59d3da491bc757c9838adb22339bf12e55d62a82

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
