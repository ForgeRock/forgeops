FROM gcr.io/forgerock-io/ig/pit1:7.2.0-83db6b3bef4df1adb738a5aaf1ea4b53e5978233

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
