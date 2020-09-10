FROM gcr.io/forgerock-io/ig:7.0.0-PAAS-GA-743ebf586bf2ebe51dc875861053c2d3cc08c6df

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
