FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-de711def826823a98382f479ce4699363c856647

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
