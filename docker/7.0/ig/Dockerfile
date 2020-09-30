FROM gcr.io/forgerock-io/ig:7.1.0-137e448094e46596d9531ab6d40898b429aa9e77

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
