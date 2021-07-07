FROM gcr.io/forgerock-io/ig/pit1:7.2.0-25f6e42330095472dd896796a34c6dbbc0535176

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
