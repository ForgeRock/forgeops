FROM gcr.io/forgerock-io/ig:7.0.0-83b9e4854a9c4fed54609ce19a157c646b0403ba

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
