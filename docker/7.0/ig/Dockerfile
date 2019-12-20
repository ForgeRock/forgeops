FROM gcr.io/forgerock-io/ig:7.0.0-f85ce882ba4ee7d1c9591e99f9475962e2fb87f3

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
