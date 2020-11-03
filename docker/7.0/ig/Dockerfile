FROM gcr.io/forgerock-io/ig:7.1.0-fe43e7076c151da6a3feac8a70eaa6069bd92962

# Copy all config files into the docker image.
# The default ig directory is /var/ig, and it expects subfolders config/ and scripts/ (if required)
COPY --chown=forgerock:root . /var/ig
