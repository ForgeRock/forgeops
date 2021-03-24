FROM gcr.io/forgerock-io/ig/pit1:7.1.0-2021-3-36f565e013ac005390591dc43afda21c1dd6c56b

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
