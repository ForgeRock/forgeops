FROM gcr.io/forgerock-io/ig:7.1.0-2021-2-86a3adc141f75a67b387c227d729bb7fc4cd74d9

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
