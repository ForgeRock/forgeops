FROM gcr.io/forgerock-io/ig:7.0.0-ec613de66bea90edf7134fadd0653e9e6cb04a64

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
