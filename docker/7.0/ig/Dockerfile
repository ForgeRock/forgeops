FROM gcr.io/forgerock-io/ig/pit1:7.1.0-29922b361c7156f6ce2257397eef5715487c570d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
