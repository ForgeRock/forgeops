FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-42aa3d9fe3584e669a05e5fee6f0ccae053a42d9

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
