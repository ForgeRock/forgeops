FROM gcr.io/forgerock-io/ig-standalone:7.0.0-a89f33efd26618393826f55d0160f5888cae718f

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
