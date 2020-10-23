FROM gcr.io/forgerock-io/ig/pit1:7.1.0-3847fb69f8e178d12885acada473711b8f0e4fac

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
