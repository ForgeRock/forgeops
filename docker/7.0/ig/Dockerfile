FROM gcr.io/forgerock-io/ig/pit1:7.1.0-a6defe460c47e6e8748420cfa5aebde5a474252a

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
