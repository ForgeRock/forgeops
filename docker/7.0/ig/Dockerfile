FROM gcr.io/forgerock-io/ig/pit1:7.1.0-8a0c4c853b587e5abec66e5163d18b9dfbef729a

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
