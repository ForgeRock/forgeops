FROM gcr.io/forgerock-io/ig/pit1:7.0.0-bcba72c7daad2f4bc10d8a9925741dd462bcf30d

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock . /var/ig
