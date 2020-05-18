FROM gcr.io/forgerock-io/ig-standalone/pit1:7.0.0-4e4013484039f815f4acae958ca7ba98b02afcd0

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
