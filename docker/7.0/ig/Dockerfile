FROM gcr.io/forgerock-io/ig:7.1.0-10ee3c7056577486f47364e71eefa71f97017ce3

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
