FROM gcr.io/forgerock-io/ig/pit1:7.1.0-2021-4-0eb6ec04f4268b687fe6a5c4b3e94bd1fe08c8ce

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
