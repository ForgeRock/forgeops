FROM gcr.io/forgerock-io/ig:7.1.0-PAAS-GA-8119f69b5af61c5857a319e1f54480ba5ab3e9fe

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
