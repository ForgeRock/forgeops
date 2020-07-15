FROM gcr.io/forgerock-io/ig:7.0.0-7ce41479c5180fd2fda97dd02e037756f49704ca

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
