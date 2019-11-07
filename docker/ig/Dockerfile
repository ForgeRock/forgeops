FROM gcr.io/forgerock-io/ig:7.0.0-16354b1b82e7b916d667d84aa693dffda88d660e

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
